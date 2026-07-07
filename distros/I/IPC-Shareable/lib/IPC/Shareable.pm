package IPC::Shareable;

use warnings;
use strict;

require 5.010;

use Carp qw(croak confess carp);
use Config;
use Errno qw(EINVAL ENOMEM ENOSPC);
use Digest::MD5 qw(md5_hex);
use IPC::Semaphore;
use IPC::Shareable::SharedMem;
use IPC::SysV qw(
    IPC_PRIVATE
    IPC_CREAT
    IPC_EXCL
    IPC_NOWAIT
    IPC_RMID
    IPC_STAT
    SEM_UNDO
);
use JSON qw(-convert_blessed_universally);
use Scalar::Util;
use String::CRC32;
use Storable 0.6 qw(freeze thaw);

our $VERSION = '1.19';

# eval() returns 1 on success; // 0 coerces undef (failure) to 0 so callers
# can boolean-test cleanly without checking definedness.

our $_have_xs = ! $ENV{IPC_SHAREABLE_NO_XS} && eval {
    require XSLoader;
    XSLoader::load('IPC::Shareable', $VERSION);
    1;
} // 0;

use constant {
    # Locking

    LOCK_SH               => 1,
    LOCK_EX               => 2,
    LOCK_NB               => 4,
    LOCK_UN               => 8,

    # SHM parameters

    SHM_BUFSIZ            => 65536,
    SHMMAX_BYTES          => 1073741824, # ~1 GB
    SHM_EXISTS            => 1,

    # Semaphore slots (4 slots always; 5th slot added when 'testing' is set)

    SEM_MARKER            => 0,
    SEM_READERS           => 1,
    SEM_WRITERS           => 2,
    SEM_PROTECTED         => 3,
    SEM_TESTING           => 4,

    # Perl sends in a double as opposed to an integer to shmat(), and on some
    # systems, this causes the IPC system to round down to the maximum integer
    # size of 0x80000000. We correct that when generating keys with CRC32.

    MAX_KEY_INT_SIZE      => 0x80000000,

    # Number of times we'll check for existing segs

    EXCLUSIVE_CHECK_LIMIT => 10,

    # Struct types

    TYPE_HASH             => 0,
    TYPE_ARRAY            => 1,
    TYPE_SCALAR           => 2,
};

require Exporter;
our @ISA = 'Exporter';
our @EXPORT_OK = qw(
    LOCK_EX
    LOCK_SH
    LOCK_NB
    LOCK_UN
    SEM_MARKER
    SEM_READERS
    SEM_WRITERS
    SEM_PROTECTED
    SEM_TESTING
);
our %EXPORT_TAGS = (
    all         => [
        qw( LOCK_EX LOCK_SH LOCK_NB LOCK_UN ),
        qw( SEM_MARKER SEM_READERS SEM_WRITERS SEM_PROTECTED SEM_TESTING ),
    ],
    lock        => [qw( LOCK_EX LOCK_SH LOCK_NB LOCK_UN )],
    flock       => [qw( LOCK_EX LOCK_SH LOCK_NB LOCK_UN )],
    semaphores  => [qw( SEM_MARKER SEM_READERS SEM_WRITERS SEM_PROTECTED SEM_TESTING )],
);

# Locking scheme copied from IPC::ShareLite (with minor modifications)

my %semop_args = (
    (LOCK_EX),
    [
        SEM_READERS, 0, 0,                        # Wait for readers to finish
        SEM_WRITERS, 0, 0,                        # Wait for writers to finish
        SEM_WRITERS, 1, SEM_UNDO,                 # Assert write lock
    ],
    (LOCK_EX|LOCK_NB),
    [
        SEM_READERS, 0, IPC_NOWAIT,               # Wait for readers to finish
        SEM_WRITERS, 0, IPC_NOWAIT,               # Wait for writers to finish
        SEM_WRITERS, 1, (SEM_UNDO | IPC_NOWAIT),  # Assert write lock
    ],
    (LOCK_EX|LOCK_UN),
    [
        SEM_WRITERS, -1, (SEM_UNDO | IPC_NOWAIT),
    ],
    (LOCK_SH),
    [
        SEM_WRITERS, 0, 0,                        # Wait for writers to finish
        SEM_READERS, 1, SEM_UNDO,                 # Assert shared read lock
    ],
    (LOCK_SH|LOCK_NB),
    [
        SEM_WRITERS, 0, IPC_NOWAIT,               # Wait for writers to finish
        SEM_READERS, 1, (SEM_UNDO | IPC_NOWAIT),  # Assert shared read lock
    ],
    (LOCK_SH|LOCK_UN),
    [
        SEM_READERS, -1, (SEM_UNDO | IPC_NOWAIT), # Remove shared read lock
    ],
);

my %default_options = (
    key                         => IPC_PRIVATE,
    create                      => 0,
    exclusive                   => 0,
    destroy                     => 0,
    mode                        => 0666,
    size                        => SHM_BUFSIZ,
    protected                   => 0,
    testing                     => 0,
    limit                       => 1,
    graceful                    => 0,
    warn                        => 0,
    serializer                  => 'json',
    enforced_write_locking      => 1,
    enforced_read_locking       => 1,
    violated_write_lock_warn    => 1,
    violated_read_lock_warn     => 1,
);

# Class-level variables

my %global_register;
my %process_register;
my %used_ids;
my $_testing_dist = '';

# Set once we have warned that a semaphore set vanished mid-unlock (a peer
# removed it). Keeps the warning to one line per process rather than per call.

my $_unlock_einval_warned = 0;

# "Magic" methods

sub TIESCALAR {
    return _tie('SCALAR', @_);
}
sub TIEARRAY {
    return _tie('ARRAY', @_);
}
sub TIEHASH {
    return _tie('HASH', @_);
}
sub STORE {
    my $knot = shift;

    return if ! _write_permitted($knot);

    $knot->{_data} = $knot->_decode($knot->seg) unless ($knot->{_lock});

    if ($knot->{_type_int} == TYPE_HASH) {
        my ($key, $val) = @_;
        _remove_child($knot->{_data}{$key});
        _magic_tie($knot, $val) if ref($val) && $knot->_need_tie($val);
        $knot->{_data}{$key} = $val;
    }
    elsif ($knot->{_type_int} == TYPE_ARRAY) {
        my ($i, $val) = @_;
        _remove_child($knot->{_data}[$i]);
        _magic_tie($knot, $val) if ref($val) && $knot->_need_tie($val);
        $knot->{_data}[$i] = $val;
    }
    elsif ($knot->{_type_int} == TYPE_SCALAR) {
        my ($val) = @_;

        if ($knot->{_data} && ref($knot->{_data})) {
            _remove_child(${$knot->{_data}});
        }
        _magic_tie($knot, $val) if ref($val) && $knot->_need_tie($val);
        $knot->{_data} = \$val;
    }

    if ($knot->{_lock} & LOCK_EX) {
        $knot->{_was_changed} = 1;
    }
    else {
        _write_to_seg($knot);
    }

    return 1;
}
sub FETCH {
    my $knot = shift;

    my $data;

    if ($knot->{_lock}) {
        $data = $knot->{_data};
    }
    else {
        _read_check($knot);
        $data = $knot->_decode($knot->seg);
        $knot->{_data} = $data;
    }

    my $val;

    if ($knot->{_type_int} == TYPE_HASH) {
        my $key = shift;
        $val = $data->{$key};
    }
    elsif ($knot->{_type_int} == TYPE_ARRAY) {
        my $i = shift;
        $val = $data->[$i];
    }
    elsif ($knot->{_type_int} == TYPE_SCALAR) {
        if (defined $data) {
            $val = $$data;
        }
        else {
            return;
        }
    }

    if (ref($val) && (my $inner = _is_child($val))) {
        # Register the inner knot so clean_up_all() can find it even when it
        # was created in a forked child process

        if (! exists $global_register{$inner->seg->id}) {
            $global_register{$inner->seg->id} = $inner;
        }

        unless ($inner->{_lock}) {
            my $s = $inner->seg;
            $inner->{_data} = $knot->_decode($s);
        }
    }
    return $val;

}
sub CLEAR {
    my $knot = shift;

    return if ! _write_permitted($knot);

    $knot->{_data} = $knot->_decode($knot->seg) unless $knot->{_lock};

    if ($knot->{_type_int} == TYPE_HASH) {
        for my $val (values %{ $knot->{_data} }) {
            _remove_child($val);
        }
        $knot->{_data} = { };
    }
    elsif ($knot->{_type_int} == TYPE_ARRAY) {
        for my $val (@{ $knot->{_data} }) {
            _remove_child($val);
        }
        $knot->{_data} = [ ];
    }

    if ($knot->{_lock} & LOCK_EX) {
        $knot->{_was_changed} = 1;
    }
    else {
        _write_to_seg($knot);
    }
}
sub DELETE {
    my $knot = shift;
    my $key  = shift;

    croak "Cannot delete from a non-hash tied variable"
        unless $knot->{_type_int} == TYPE_HASH;

    return if ! _write_permitted($knot);

    $knot->{_data} = $knot->_decode($knot->seg) unless $knot->{_lock};
    my $val = delete $knot->{_data}->{$key};

    _remove_child($val);

    if ($knot->{_lock} & LOCK_EX) {
        $knot->{_was_changed} = 1;
    }
    else {
        _write_to_seg($knot);
    }

    return $val;
}
sub EXISTS {
    my $knot = shift;
    my $key  = shift;

    $knot->{_data} = $knot->_decode($knot->seg) unless $knot->{_lock};
    return exists $knot->{_data}->{$key};
}
sub FIRSTKEY {
    my $knot = shift;
    $knot->{_data} = $knot->_decode($knot->seg) unless $knot->{_lock};
    $knot->{_hkey_list} = [ keys %{$knot->{_data}} ];
    return $knot->NEXTKEY;
}
sub NEXTKEY {
    my ($knot, $last_key_accessed) = @_;

    # We don't use ordered hashes, so we don't need to use
    # the last key accessed parameter

    # Caveat emptor if hash was changed by another process

    return shift @{$knot->{_hkey_list}};
}
sub EXTEND {
    #XXX Noop
}
sub PUSH {
    my $knot = shift;

    croak "Cannot push to a non-array tied variable"
        unless $knot->{_type_int} == TYPE_ARRAY;

    return if ! _write_permitted($knot);

    $knot->{_data} = $knot->_decode($knot->seg, $knot->{_data}) unless $knot->{_lock};

    push @{$knot->{_data}}, @_;
    if ($knot->{_lock} & LOCK_EX) {
        $knot->{_was_changed} = 1;
    }
    else {
        _write_to_seg($knot);
    }
}
sub POP {
    my $knot = shift;

    croak "Cannot pop from a non-array tied variable"
        unless $knot->{_type_int} == TYPE_ARRAY;

    return if ! _write_permitted($knot);

    $knot->{_data} = $knot->_decode($knot->seg, $knot->{_data}) unless $knot->{_lock};

    my $val = pop @{$knot->{_data}};
    if ($knot->{_lock} & LOCK_EX) {
        $knot->{_was_changed} = 1;
    }
    else {
        _write_to_seg($knot);
    }
    return $val;
}
sub SHIFT {
    my $knot = shift;

    croak "Cannot shift from a non-array tied variable"
        unless $knot->{_type_int} == TYPE_ARRAY;

    return if ! _write_permitted($knot);

    $knot->{_data} = $knot->_decode($knot->seg, $knot->{_data}) unless $knot->{_lock};
    my $val = shift @{$knot->{_data}};
    if ($knot->{_lock} & LOCK_EX) {
        $knot->{_was_changed} = 1;
    }
    else {
        _write_to_seg($knot);
    }
    return $val;
}
sub UNSHIFT {
    my $knot = shift;

    croak "Cannot unshift a non-array tied variable"
        unless $knot->{_type_int} == TYPE_ARRAY;

    return if ! _write_permitted($knot);

    $knot->{_data} = $knot->_decode($knot->seg, $knot->{_data}) unless $knot->{_lock};
    my $val = unshift @{$knot->{_data}}, @_;
    if ($knot->{_lock} & LOCK_EX) {
        $knot->{_was_changed} = 1;
    }
    else {
        _write_to_seg($knot);
    }
    return $val;
}
sub SPLICE {
    my($knot, $off, $n, @av) = @_;

    croak "Cannot splice a non-array tied variable"
        unless $knot->{_type_int} == TYPE_ARRAY;

    return if ! _write_permitted($knot);

    $knot->{_data} = $knot->_decode($knot->seg, $knot->{_data}) unless $knot->{_lock};
    my @val = splice @{$knot->{_data}}, $off, $n, @av;
    if ($knot->{_lock} & LOCK_EX) {
        $knot->{_was_changed} = 1;
    }
    else {
        _write_to_seg($knot);
    }
    return @val;
}
sub FETCHSIZE {
    my $knot = shift;

    croak "Cannot fetchsize on a non-array tied variable"
        unless $knot->{_type_int} == TYPE_ARRAY;

    $knot->{_data} = $knot->_decode($knot->seg) unless $knot->{_lock};
    return scalar(@{$knot->{_data}});
}
sub STORESIZE {
    my $knot = shift;
    my $n    = shift;

    croak "Cannot storesize on a non-array tied variable"
        unless $knot->{_type_int} == TYPE_ARRAY;

    return if ! _write_permitted($knot);

    $knot->{_data} = $knot->_decode($knot->seg) unless $knot->{_lock};
    $#{$knot->{_data}} = $n - 1;

    if ($knot->{_lock} & LOCK_EX) {
        $knot->{_was_changed} = 1;
    }
    else {
        _write_to_seg($knot);
    }
    return $n;
}

# Public methods

*shlock = \&lock;
*shunlock = \&unlock;

# End user methods

sub new {
    my ($class, %opts) = @_;

    my $type = $opts{var} || 'HASH';

    if ($type eq 'HASH') {
        tie my %h, 'IPC::Shareable', \%opts;
        return \%h;
    }
    if ($type eq 'ARRAY') {
        tie my @a, 'IPC::Shareable', \%opts;
        return \@a;
    }
    if ($type eq 'SCALAR') {
        tie my $s, 'IPC::Shareable', \%opts;
        return \$s;
    }
}
sub lock {
    my $knot = shift;

    my ($flags, $code);

    if (scalar @_ == 2) {
        ($flags, $code) = @_;
    }

    if (defined $_[0]) {
        if (ref $_[0] eq 'CODE') {
            $code = shift;
        }
        else {
            $flags = shift;
        }
    }

    if (defined $code && ref $code ne 'CODE') {
        croak "\$code param to lock() must be a code reference";
    }

    $flags = LOCK_EX if ! defined $flags;

    # unlock() was called

    return $knot->unlock if ($flags & LOCK_UN);

    # Caller already has the same lock type

    if ($knot->{_lock} & $flags) {
        if ($code && $flags == LOCK_EX) {
            _execute_lock_coderef($knot, $code);
        }
        return 1;
    }

    # If they have a different lock than they want, release it first

    $knot->unlock if ($knot->{_lock});

    my $sem = $knot->sem;
    my $lock_success = $sem->op(@{ $semop_args{$flags} });

    if ($lock_success) {
        $knot->{_lock} = $flags;
        $knot->{_data} = $knot->_decode($knot->seg);

        my $locked_ref = _lock_children($knot, $flags);

        if (! $locked_ref) {
            my $rflags = $knot->{_lock} | LOCK_UN;
            $rflags ^= LOCK_NB if $rflags & LOCK_NB;
            $knot->sem->op(@{ $semop_args{$rflags} });
            $knot->{_lock} = 0;
            $lock_success  = 0;
        }
        else {
            $knot->{_locked_children} = $locked_ref;
        }
    }

    if ($flags == LOCK_EX && $lock_success && $code) {
        _execute_lock_coderef($knot, $code);
        return 1;
    }
    return $lock_success;
}
sub unlock {
    my $knot = shift;

    return 1 unless $knot->{_lock};

    if ($knot->{_was_changed}) {
        _write_to_seg($knot);
        $knot->{_was_changed} = 0;
    }

    # Unlock children/nested segs in reverse order

    for my $child (reverse @{ $knot->{_locked_children} // [] }) {
        if ($child->{_was_changed}) {
            _write_to_seg($child);
            $child->{_was_changed} = 0;
        }

        my $child_flags = $child->{_lock} | LOCK_UN;

        $child_flags ^= LOCK_NB if $child_flags & LOCK_NB;
        $child->sem->op(@{ $semop_args{$child_flags} });
        $child->{_lock} = 0;
    }

    $knot->{_locked_children} = [];

    # Release semaphore locks

    my $sem = $knot->sem;
    my $flags = $knot->{_lock} | LOCK_UN;

    $flags ^= LOCK_NB if ($flags & LOCK_NB);

    if (! $sem->op(@{ $semop_args{$flags} })) {
        if ($!{EINVAL}) {
            # The semaphore set was removed by another process (eg. a peer
            # holding the same segment with destroy=>1 exited). The lock we
            # held went away with it, so there is nothing left to release.
            # Warn once and carry on rather than aborting the caller; every
            # other errno is a real failure and stays fatal. This mirrors the
            # read path's tolerance of an unreachable set (see _write_permitted
            # and _check_read_lock).

            carp "Semaphore set gone during unlock (removed by another "
               . "process); treating the lock as already released"
                if ! $_unlock_einval_warned;

            $_unlock_einval_warned = 1;
        }
        else {
            croak "Could not release semaphore lock: $!\n";
        }
    }

    $knot->{_lock} = 0;

    1;
}
sub singleton {

    # If called with IPC::Shareable::singleton() as opposed to
    # IPC::Shareable->singleton(), the class isn't sent in. Check
    # for this and fix it if necessary

    if (! defined $_[0] || $_[0] ne __PACKAGE__) {
        unshift @_, __PACKAGE__;
    }

    my ($class, $glue, $warn) = @_;

    if (! defined $glue) {
        croak "singleton() requires a GLUE parameter";
    }

    $warn = 0 if ! defined $warn;

    tie my $lock, 'IPC::Shareable', {
        key         => $glue,
        create      => 1,
        exclusive   => 1,
        graceful    => 1,
        destroy     => 1,
        warn        => $warn
    };

    return $$;
}

# Helper, maintenance and developer methods

sub attributes {
    my ($knot, $attr) = @_;

    if (defined $attr) {
        return $knot->{attributes}{$attr};
    }
    else {
        return $knot->{attributes};
    }
}
sub global_register {
    return \%global_register;
}
sub process_register {
    return \%process_register;
}
sub uuid {
    my ($knot) = @_;

    if (! defined $knot->{_uuid}) {
        $knot->{_uuid} = md5_hex(rand());
    }

    return $knot->{_uuid};
}

sub seg {
    my ($knot) = @_;
    return $knot->{_shm} if defined $knot->{_shm};
}
sub sem {
    my ($knot) = @_;
    return $knot->{_sem} if defined $knot->{_sem};
}

sub shm_segments {
    shift if ref($_[0]) || (defined $_[0] && ! ref($_[0]) && UNIVERSAL::isa($_[0], __PACKAGE__));

    my ($filter_key) = @_;

    my $filter_int = _key_str_to_int($filter_key) if defined $filter_key;

    my %segments;

    open my $ipcs_fh, '-|', 'ipcs', '-m' or die "ipcs -m: $!";

    while (my $line = <$ipcs_fh>) {
        my ($id, $raw_key);

        if ($line =~ /^\s*m\s+(\d+)\s+(\S+)/) {
            # BSD/macOS format: m <shmid> <key> ...
            ($id, $raw_key) = ($1, $2);
        }
        elsif ($line =~ /^\s*(\d+)\s+(0x[0-9a-fA-F]+)\s+/) {
            # DragonFly BSD format: <shmid> <hex_key> ... (no 'm' type column)
            ($id, $raw_key) = ($1, $2);
        }
        elsif ($line =~ /^\s*(\S+)\s+(\d+)\s+\S+/) {
            # Linux format: <key> <shmid> ...
            ($raw_key, $id) = ($1, $2);
        }
        else {
            next;
        }

        my $key_int = $raw_key =~ /^0x[0-9a-fA-F]+$/
            ? hex($raw_key)
            : $raw_key =~ /^\d+$/
            ? int($raw_key)
            : next;

        my $hex_key = sprintf('0x%08x', $key_int);

        next if $key_int == 0;  # IPC_PRIVATE segments can't be found by key

        # Get segment size via IPC_STAT

        my $stat_buf = '';
        shmctl($id, IPC_STAT, $stat_buf) or next;

        my ($segsz) = $^O eq 'linux'
            ? ( $Config{longsize} == 8
            ? unpack('x[48] Q', $stat_buf)   # 64-bit Linux
            : unpack('x[36] L', $stat_buf) ) # 32-bit Linux
            : $^O eq 'freebsd' && $Config{longsize} == 8
            ? unpack('x[32] Q', $stat_buf)   # 64-bit FreeBSD (key_t=long=8, ipc_perm=32)
            : $^O eq 'solaris'
            ? ( $Config{longsize} == 8
            ? unpack('x[32] Q', $stat_buf)   # 64-bit Solaris (ipc_perm=28 + pad 4)
            : unpack('x[44] L', $stat_buf) ) # 32-bit Solaris (ipc_perm=44)
            : $^O eq 'openbsd' && $Config{longsize} == 8
            ? unpack('x[32] L', $stat_buf)   # 64-bit OpenBSD: segsz is int (4 bytes)
            : $^O eq 'dragonfly' && $Config{longsize} == 8
            ? unpack('x[32] Q', $stat_buf)   # 64-bit DragonFly (ipc_perm=28 + pad 4; segsz=size_t=8)
            : unpack('x[24] Q', $stat_buf);  # macOS

        next unless $segsz;

        # Probe the 14-byte tag first so we don't pull entire foreign
        # segments (which may be gigabytes) into Perl just to discard them.

        my $head = '';
        shmread($id, $head, 0, 14) or next;
        next unless $head eq 'IPC::Shareable';

        my $data = '';
        shmread($id, $data, 0, $segsz) or next;

        # Strip trailing null bytes
        $data =~ s/\x00+$//;

        my $json_part  = substr($data, 14);
        my @child_keys = ($json_part =~ /"child_key_hex":"([^"]+)"/g);

        $segments{$hex_key} = {
            child_keys    => \@child_keys,
            content       => $data,
            id            => $id,
            local_process => (exists $process_register{$id} ? 1 : 0),
            known         => (exists $global_register{$id}  ? 1 : 0),
        };
    }
    close $ipcs_fh;

    if (defined $filter_int) {
        # Walk the segment tree starting from the root whose key matches
        # $filter_int, collecting it and all its descendants.  Use integer
        # comparison so that hex formatting differences (zero-padding, case)
        # between ipcs(1) output and child_key_hex values don't matter.

        my %int_to_hex = map { hex($_) => $_ } keys %segments;

        my (%related, @queue);

        push @queue, $filter_int;

        while (my $k_int = shift @queue) {
            my $k_hex = $int_to_hex{$k_int} // next;
            next if $related{$k_hex}++;
            push @queue, map { hex($_) } @{ $segments{$k_hex}{child_keys} };
        }

        %segments = map { $_ => $segments{$_} } keys %related;
    }

    return \%segments;
}
sub unknown_segments {
    shift if ref $_[0]; # Allow for object or class method call

    my $segs = shm_segments();

    return grep { ! $segs->{$_}{known} } keys %$segs;
}
sub seg_count {
    my $count = 0;

    open my $ipcs_fh, '-|', 'ipcs', '-m' or die "ipcs -m: $!";

    while (my $line = <$ipcs_fh>) {
        if ($line =~ /^\s*m\s+\d+\s+\S+/) {
            # BSD/macOS format: m <shmid> <key> ...
            $count++;
        }
        elsif ($line =~ /^\s*\d+\s+0x[0-9a-fA-F]+\s+/) {
            # DragonFly BSD: <shmid> <hex_key> ... (no type-letter column)
            $count++;
        }
        elsif ($line =~ /^\s*(?:0x[0-9a-fA-F]+|\d+)\s+\d+\s+\S+/) {
            # Linux format: <key> <shmid> ...
            $count++;
        }
    }

    close $ipcs_fh;

    return $count;
}
sub sem_count {
    my $count = 0;

    open my $ipcs_fh, '-|', 'ipcs', '-s' or die "ipcs -s: $!";

    while (my $line = <$ipcs_fh>) {
        if ($line =~ /^\s*s\s+\d+\s+\S+/) {
            # BSD/macOS format: s <semid> <key> ...
            $count++;
        }
        elsif ($line =~ /^\s*\d+\s+0x[0-9a-fA-F]+\s+/) {
            # DragonFly BSD: <semid> <hex_key> ... (no type-letter column)
            $count++;
        }
        elsif ($line =~ /^\s*(?:0x[0-9a-fA-F]+|\d+)\s+\d+\s+\S+/) {
            # Linux format: <key> <semid> ...
            $count++;
        }
    }

    close $ipcs_fh;

    return $count;
}
sub seg_map {
    croak "seg_map() must be called as an object method" unless ref $_[0];
    my $knot_filter = shift;

    my $segs = shm_segments();

    # Build hex_key -> OS segment ID from shm_segments() data

    my %id_by_hex;
    $id_by_hex{ $_ } = $segs->{$_}{id} for keys %$segs;

    # Build hex_key -> knot from global_register (keyed by seg_id)

    my %knot_by_hex;
    for my $id (keys %global_register) {
        my $knot = $global_register{$id};
        my $hex  = $knot->{_key_hex};

        $knot_by_hex{$hex} = $knot if defined $hex;
    }

    # Supplement child_keys from global_register for Storable segments.
    # shm_segments() only extracts child_key_hex from JSON segment content;
    # for Storable we walk each knot's _data looking for tied child references

    my %extra_child_keys;   # hex_key -> [ child_hex, ... ]

    for my $hex (keys %knot_by_hex) {
        my $knot  = $knot_by_hex{$hex};
        my $data  = $knot->{_data};
        my $rtype = Scalar::Util::reftype($data) // '';

        my @vals = $rtype eq 'HASH'  ? values %$data
                 : $rtype eq 'ARRAY' ? @$data
                 : ();

        for my $v (@vals) {
            next unless ref($v);

            my $vtype = Scalar::Util::reftype($v) // '';
            my $child_knot;

            if ($vtype eq 'HASH')   {
                $child_knot = tied(%$v)
            }
            elsif ($vtype eq 'ARRAY')  {
                $child_knot = tied(@$v)
            }
            elsif ($vtype eq 'SCALAR') {
                $child_knot = tied($$v)
            }

            next unless $child_knot && $child_knot->{_key_hex};

            push @{ $extra_child_keys{$hex} }, $child_knot->{_key_hex};
        }
    }

    # If called as an object method, restrict output to just that knot's tree
    # by BFS through both child_keys (JSON) and extra_child_keys (Storable).

    if ($knot_filter && $knot_filter->{_key_hex}) {
        my $root_hex = $knot_filter->{_key_hex};
        my (%in_tree, @queue);

        push @queue, $root_hex;

        while (my $h = shift @queue) {
            next if $in_tree{$h}++;

            push @queue, @{ $segs->{$h}{child_keys}   // [] };
            push @queue, @{ $extra_child_keys{$h}     // [] };
        }

        %$segs = map { $_ => $segs->{$_} } grep { $in_tree{$_} } keys %$segs;
    }

    # Identify root segments (not a child of any other segment)

    my %is_child;

    for my $hex (keys %$segs) {
        $is_child{$_}++ for @{ $segs->{$hex}{child_keys} };
    }

    for my $hex (keys %extra_child_keys) {
        next unless exists $segs->{$hex};
        $is_child{$_}++ for @{ $extra_child_keys{$hex} };
    }

    my @roots = sort grep { ! $is_child{$_} } keys %$segs;

    my @lines;
    push @lines, 'IPC::Shareable Segment Map';
    push @lines, '=' x 26;

    if (! @roots) {
        push @lines, '';
        push @lines, '  (no IPC::Shareable segments found)';
        return join("\n", @lines) . "\n";
    }

    my $render;

    $render = sub {
        my ($hex, $depth) = @_;
        my $indent = '  ' x $depth;
        my $seg    = $segs->{$hex} // {};

        my @tags;
        push @tags, $seg->{known} ? 'known' : 'unknown';
        push @tags, 'owner' if $seg->{local_process};
        my $tag_str = '[' . join(', ', @tags) . ']';

        my $seg_id = $id_by_hex{$hex} // '?';

        # Read semaphore slot values and ID; for segments not in
        # global_register attach with nsems=0 (avoids EINVAL on existing sets)

        my ($sem_str, $content_str);

        my $sem = $knot_by_hex{$hex}
            ? $knot_by_hex{$hex}->sem
            : IPC::Semaphore->new(hex($hex), 0, 0);

        if (defined $sem) {
            my $sem_id    = $sem->id                    // '?';
            my $marker    = $sem->getval(SEM_MARKER)    // '?';
            my $readers   = $sem->getval(SEM_READERS)   // '?';
            my $writers   = $sem->getval(SEM_WRITERS)   // '?';
            my $protected = $sem->getval(SEM_PROTECTED) // '?';

            # Continuation indent: one tab (8 spaces) from the left margin
            my $cont = ' ' x 8;

            $sem_str = join("\n",
                "sem_id: $sem_id",
                "${cont}1: SEM_MARKER=$marker",
                "${cont}2: READERS=$readers",
                "${cont}3: WRITERS=$writers",
                "${cont}4: PROTECTED=$protected",
            );
        }
        else {
            $sem_str = '(not accessible)';
        }

        $content_str = $knot_by_hex{$hex}
            ? _shm_data_summary($knot_by_hex{$hex})
            : '(not accessible - segment not tied in this process)';

        # Merge child keys from shm_segments() and from global_register walk

        my %seen_child;

        my @child_keys = grep { ! $seen_child{$_}++ } (
            @{ $seg->{child_keys} // [] },
            @{ $extra_child_keys{$hex} // [] },
        );

        my $children = @child_keys ? join(', ', @child_keys) : '(none)';

        push @lines, '';
        push @lines, "${indent}${tag_str}  key: ${hex}  seg_id: ${seg_id}";
        push @lines, "${indent}  Semaphores: ${sem_str}";
        push @lines, "${indent}  Children:   ${children}";
        push @lines, "${indent}  Content:    ${content_str}";

        $render->($_, $depth + 1) for @child_keys;
    };

    $render->($_, 0) for @roots;

    push @lines, '';

    return join("\n", @lines) . "\n";
}
sub sysv_info {
    shift; # Discard invocant (object ref or class name)

    my %opts       = @_;

    my $proc_dir   = delete $opts{_proc_dir}   // '/proc/sys/kernel';
    my $sysctl_out = delete $opts{_sysctl_out};

    my %info;

    if ($^O eq 'darwin') {
        my $out = defined $sysctl_out ? $sysctl_out : do {
            open my $fh, '-|', 'sysctl', 'kern.sysv' or die "sysctl: $!";
            local $/;
            my $s = <$fh>;
            close $fh;
            $s;
        };
        for my $line (split /\n/, $out) {
            if ($line =~ /^kern\.sysv\.(\w+):\s*(\S+)/) {
                $info{$1} = $2;
            }
        }
    }
    elsif ($^O eq 'freebsd' || $^O eq 'midnightbsd' || $^O eq 'netbsd') {
        # MidnightBSD (FreeBSD-derived) and NetBSD share FreeBSD's kern.ipc
        # sysctl namespace. NetBSD's semmni also defaults to 10, so exposing
        # the limit there lets the test suite's free-set guard activate
        # instead of dying ENOSPC mid-run.

        my $out = defined $sysctl_out ? $sysctl_out : do {
            open my $fh, '-|', 'sysctl', 'kern.ipc' or die "sysctl: $!";
            local $/;
            my $s = <$fh>;
            close $fh;
            $s;
        };
        for my $line (split /\n/, $out) {
            if ($line =~ /^kern\.ipc\.((?:shm|sem)\w+)\s*[:=]\s*(\S+)/) {
                $info{$1} = $2;
            }
        }
    }
    elsif ($^O eq 'openbsd') {
        my $out = defined $sysctl_out ? $sysctl_out : do {
            open my $fh, '-|', 'sysctl', 'kern.seminfo', 'kern.shminfo'
                or die "sysctl: $!";
            local $/;
            my $s = <$fh>;
            close $fh;
            $s;
        };
        for my $line (split /\n/, $out) {
            if ($line =~ /^kern\.(?:sem|shm)info\.(\w+)\s*=\s*(\S+)/) {
                $info{$1} = $2;
            }
        }
    }
    elsif ($^O eq 'linux') {
        for my $key (qw(shmmax shmmin shmmni shmall)) {
            my $file = "$proc_dir/$key";
            if (open my $fh, '<', $file) {
                chomp(my $val = <$fh>);
                $info{$key} = $val;
            }
        }
        # /proc/sys/kernel/sem is a single line of 4 ints:
        #   semmsl semmns semopm semmni
        if (open my $fh, '<', "$proc_dir/sem") {
            chomp(my $line = <$fh>);
            close $fh;
            my @vals = split /\s+/, $line;
            if (@vals >= 4) {
                @info{qw(semmsl semmns semopm semmni)} = @vals[0..3];
            }
        }
    }

    return %info ? \%info : undef;
}

# Cleanup

sub clean_up {
    my $class = shift;

    for my $id (keys %process_register) {
        my $s = $process_register{$id};
        next unless $s->attributes('owner') == $$;
        next if $s->attributes('protected');
        remove($s);
    }
}
sub clean_up_all {
    my $class = shift;

    my $global_register = __PACKAGE__->global_register;

    for my $id (keys %$global_register) {
        my $s = $global_register->{$id};
        next if $s->attributes('protected');
        remove($s);
    }
}
sub clean_up_protected {
    my ($knot, $protect_key);

    if (scalar @_ == 2) {
        ($knot, $protect_key) = @_;
    }
    if (scalar @_ == 1) {
        ($protect_key) = @_;
    }

    if (! defined $protect_key) {
        croak "clean_up_protected() requires a \$protect_key param";
    }

    if ($protect_key !~ /^\d+$/) {
        croak
            "clean_up_protected() \$protect_key must be an integer. You sent $protect_key";
    }

    my $global_register = __PACKAGE__->global_register;

    for my $id (keys %$global_register) {
        my $s = $global_register->{$id};
        my $stored_key = $s->attributes('protected');

        if ($stored_key && $stored_key == $protect_key) {
            remove($s);
        }
    }
}
sub remove {
    my ($knot, $key) = @_;

    # If a key is passed, remove that specific segment by key rather than
    # via an existing tied object

    if (defined $key) {
        $key = $knot->_shm_key($key);
        my $id = shmget($key, 0, 0);

        if (! defined $id) {
            warn "remove(): shmget failed for key $key: $!";
            return;
        }

        if (! shmctl($id, IPC_RMID, 0)) {
            warn "Couldn't remove shm segment $id: $!";
        }
        else {
            delete $process_register{$id};
            delete $global_register{$id};
        }

        # Remove the associated semaphore set (same key, attach-only with nsems=0)

        my $sem = IPC::Semaphore->new($key, 0, 0);
        if (defined $sem) {
            $sem->remove or warn "Couldn't remove semaphore set for key $key: $!";
        }

        return;
    }

    # Standard object based removal

    my $seg = $knot->seg;
    my $id = $seg->id;

    my $seg_removed = 0;

    if (! $seg->remove) {
        warn "Couldn't remove shm segment $id: $!";
    }
    else {
        $seg_removed = 1;
    }

    # Semaphore cleanup

    my $sem = $knot->sem;

    my $sem_removed = 0;
    my $sem_remove_status = $sem->remove;

    if ($sem_remove_status != 1 && $sem_remove_status ne '0 but true') {
        warn "Couldn't remove semaphore set $id: $!";
    }
    else {
        $sem_removed = 1;
    }

    # If the segment or semaphore couldn't be cleaned up, we need to
    # keep state

    if ($seg_removed && $sem_removed) {
        delete $process_register{$id};
        delete $global_register{$id};
    }
}

# Unit testing

sub testing_set {
    my ($class, $dist_name) = @_;

    croak "testing_set() requires a distribution name string"
        unless defined $dist_name && length $dist_name;

    $_testing_dist = $dist_name;
}
sub clean_up_testing {
    shift if @_ > 1 && ! ref $_[0] && defined $_[0] && UNIVERSAL::isa($_[0], __PACKAGE__);

    my ($dist_name) = @_;

    croak "clean_up_testing() requires a distribution name string"
        unless defined $dist_name && length $dist_name;

    my $target  = _testing_semaphore_key_hash($dist_name);
    my $removed = 0;

    # Scan ipcs -m for segment IDs and keys directly. We cannot use
    # shm_segments() here because it filters by the 'IPC::Shareable' 14-byte
    # tag, which is only written during STORE operations — empty tied segments
    # have no tag and would be invisible. The authoritative identifier for a
    # testing-tagged segment is the SEM_TESTING value on its semaphore set,
    # not the segment content.

    open my $ipcs_fh, '-|', 'ipcs', '-m' or die "ipcs -m: $!";

    while (my $line = <$ipcs_fh>) {
        my ($id, $raw_key);

        if ($line =~ /^\s*m\s+(\d+)\s+(\S+)/) {
            # BSD/macOS: m <shmid> <key> ...
            ($id, $raw_key) = ($1, $2);
        }
        elsif ($line =~ /^\s*(\d+)\s+(0x[0-9a-fA-F]+)\s+/) {
            # DragonFly BSD: <shmid> <hex_key> ... (no type-letter column)
            ($id, $raw_key) = ($1, $2);
        }
        elsif ($line =~ /^\s*(\S+)\s+(\d+)\s+\S+/) {
            # Linux: <key> <shmid> ...
            ($raw_key, $id) = ($1, $2);
        }
        else {
            next;
        }

        my $key_int = $raw_key =~ /^0x[0-9a-fA-F]+$/
            ? hex($raw_key)
            : $raw_key =~ /^-?\d+$/
            ? int($raw_key)
            : next;

        # IPC_PRIVATE segments cannot be re-attached across processes
        next if $key_int == 0;

        my $sem = IPC::Semaphore->new($key_int, 0, 0);
        next unless defined $sem;

        next unless _testing_semaphore_value($sem) == $target;

        # Don't tear down a segment another *live* process owns -- eg. a sibling
        # test file under `prove -j`, or a concurrent smoker testing the same
        # dist. Segments this process created ($cpid == $$), and orphans whose
        # creator process has exited, are still removed.

        my $probe = bless {}, 'IPC::Shareable::SharedMem';
        $probe->id($id);

        my $stat = eval { $probe->stat };
        my $cpid = defined $stat ? $stat->cpid : undef;

        next if defined $cpid && $cpid > 0 && $cpid != $$ && kill 0, $cpid;

        if (shmctl($id, IPC_RMID, 0)) {
            $sem->remove;
            delete $process_register{$id};
            delete $global_register{$id};
            $removed++;
        }
        else {
            warn "clean_up_testing(): could not remove shm segment $id: $!";
        }
    }
    close $ipcs_fh;

    # Second pass: reclaim orphaned testing-tagged semaphore sets -- ones whose
    # shm segment is already gone (eg. a crashed run died between removing the
    # segment and removing its semaphore set). The first pass cannot see these
    # because it walks ipcs -m. Each orphan pins a SEMMNI slot forever, and on
    # hosts with a tiny limit (OpenBSD defaults to kern.seminfo.semmni=10) the
    # accumulation eventually starves every subsequent semget() into ENOSPC --
    # the mass CPAN tester failure mode. A tagged set whose segment is gone can
    # never be re-attached by _tie() (the segment is always created before the
    # semaphore set), so removing it is race-free.

    open $ipcs_fh, '-|', 'ipcs', '-s' or die "ipcs -s: $!";

    while (my $line = <$ipcs_fh>) {
        my $raw_key;

        if ($line =~ /^\s*s\s+\d+\s+(\S+)/) {
            # BSD/macOS: s <semid> <key> ...
            $raw_key = $1;
        }
        elsif ($line =~ /^\s*\d+\s+(0x[0-9a-fA-F]+)\s+/) {
            # DragonFly BSD: <semid> <hex_key> ... (no type-letter column)
            $raw_key = $1;
        }
        elsif ($line =~ /^\s*(\S+)\s+\d+\s+\S+/) {
            # Linux: <key> <semid> ...
            $raw_key = $1;
        }
        else {
            next;
        }

        my $key_int = $raw_key =~ /^0x[0-9a-fA-F]+$/
            ? hex($raw_key)
            : $raw_key =~ /^-?\d+$/
            ? int($raw_key)
            : next;

        next if $key_int == 0;

        # A live segment means a healthy (or first-pass handled) pair

        next if defined shmget($key_int, 0, 0);

        my $sem = IPC::Semaphore->new($key_int, 0, 0);
        next unless defined $sem;

        next unless _testing_semaphore_value($sem) == $target;

        $removed++ if $sem->remove;
    }
    close $ipcs_fh;

    return $removed;
}

# Private methods

# Encoding/Decoding

sub _encode {
    my ($knot, $seg, $data) = @_;

    # A scalar tie() holding a plain (defined, non-ref) value is stored verbatim
    # in a single segment — no serializer wrapping or escaping. Automatic and
    # serializer-agnostic; refs and undef fall through to the configured
    # serializer (refs fan out / freeze; undef → {"__sv__":null} / storable).

    if ($knot->{_type_int} == TYPE_SCALAR && ref($data) eq 'SCALAR') {
        my $val = $$data;

        if (defined $val && ! ref $val) {
            return _encode_verbatim($seg, $val);
        }
    }

    my $serializer = $knot->attributes('serializer');

    if ($serializer eq 'storable') {
        return _freeze($seg, $data);
    }

    return _encode_json($seg, $data);
}
sub _decode {
    my ($knot, $seg) = @_;

    # A scalar tie's value may have been stored verbatim (tag + \x1e sentinel);
    # recognize that and short-circuit before serializer dispatch, regardless of
    # json/storable.

    if ($knot->{_type_int} == TYPE_SCALAR) {
        my $verbatim = _decode_verbatim($seg);
        return $verbatim if defined $verbatim;
    }

    my $serializer = $knot->attributes('serializer');

    my $data = $serializer eq 'storable'
        ? _thaw($seg)
        : _decode_json($seg, $knot);

    return $data if defined $data;

    # Empty/never-written segment — return appropriate empty default so that
    # aggregate tie methods (FETCHSIZE, PUSH, CLEAR, etc.) can deref safely.

    return [] if $knot->{_type_int} == TYPE_ARRAY;
    return {} if $knot->{_type_int} == TYPE_HASH;

    return undef;
}
sub _encode_json {
    my $seg  = shift;
    my $data = shift;

    my $json = encode_json _encode_json_prepare($data);

    substr $json, 0, 0, 'IPC::Shareable';

    if (length($json) > $seg->size) {
        croak "Length of shared data exceeds shared segment size";
    }

    $seg->shmwrite($json);
}
sub _encode_json_prepare {
    my ($data) = @_;

    my $type = Scalar::Util::reftype($data) or return $data;

    # Replace direct IPC::Shareable child segments with __ics__ markers.

    # All nested refs are tied children — no recursion needed; each child
    # segment encodes its own children independently. We have to do this because
    # JSON can't store blessed objects

    if ($type eq 'HASH') {
        {
            my $has_child = 0;
            for my $val (values %$data) {
                if (ref($val) && _is_child($val)) {
                    $has_child = 1;
                    last;
                }
            }
            return $data if ! $has_child;
        }

        my %result;

        for my $key (keys %$data) {
            my $val   = $data->{$key};
            my $inner = ref($val) && _is_child($val);

            $result{$key} = $inner
                ? { '__ics__' => { type => $inner->{_type}, child_key => $inner->{_key}, child_key_hex => sprintf('0x%08x', $inner->{_key}) } }
                : $val;
        }

        return \%result;
    }

    if ($type eq 'ARRAY') {
        {
            my $has_child = 0;
            for my $val (@$data) {
                if (ref($val) && _is_child($val)) {
                    $has_child = 1;
                    last;
                }
            }
            return $data if ! $has_child;
        }

        return [
            map {
                my $inner = ref($_) && _is_child($_);
                $inner
                    ? { '__ics__' => { type => $inner->{_type}, child_key => $inner->{_key}, child_key_hex => sprintf('0x%08x', $inner->{_key}) } }
                    : $_
            } @$data
        ];
    }

    if ($type eq 'SCALAR' || $type eq 'REF') {
        my $val   = $$data;
        my $inner = ref($val) && _is_child($val);

        return $inner
            ? { '__ics__' => { type => $inner->{_type}, child_key => $inner->{_key}, child_key_hex => sprintf('0x%08x', $inner->{_key}) } }
            : { '__sv__' => $val };
    }

    return $data;
}
sub _decode_json {
    my ($seg, $knot) = @_;

    my $json = $seg->data;

    return if ! $json;

    # The return of shmread() is the actual size of the defined size of the
    # shared memory segment. Even if the return equates to an empty string
    # (which it will if it contains no data), there will always be a length().
    # Therefore, we must see if we've tagged this data as a valid structure,
    # or else decode will fail

    my $tag = substr $json, 0, 14, '';

    if ($tag eq 'IPC::Shareable') {
        my $data = decode_json $json;

        if (! defined($data)) {
            croak "Munged shared memory segment (size exceeded?)";
        }

        if (defined $knot && index($json, '"__ics__"') >= 0) {
            _decode_json_restore($data, $knot)
        }

        # Unwrap scalar-tie values encoded as { '__sv__' => val } or
        # { '__ics__' => {...} }

        if (defined $knot && $knot->{_type_int} == TYPE_SCALAR && ref($data) eq 'HASH') {
            if (exists $data->{'__ics__'}) {
                my $prev     = $knot->{_data};
                my $prev_val = (defined $prev && ref($prev)) ? $$prev : undef;
                my $resolved = _decode_json_resolve($data->{'__ics__'}, $prev_val, $knot);
                return \$resolved;
            }
            if (exists $data->{'__sv__'}) {
                my $val = $data->{'__sv__'};
                return \$val;
            }
        }

        return $data;
    }
    else {
        return;
    }
}
sub _decode_json_restore {
    my ($data, $knot) = @_;

    my $type = Scalar::Util::reftype($data) or return;

    # Reuse existing tied child refs from previous decode where possible.
    # This avoids a shmget+semget system call pair for each child on every
    # decode cycle — only the first attach per segment incurs that cost.

    my $prev = $knot->{_data};

    if ($type eq 'HASH') {
        my $prev_is_hash = ref($prev) eq 'HASH';

        for my $key (keys %$data) {
            next unless ref($data->{$key}) eq 'HASH' && exists $data->{$key}{'__ics__'};

            $data->{$key} = _decode_json_resolve(
                $data->{$key}{'__ics__'},
                $prev_is_hash ? $prev->{$key} : undef,
                $knot,
            );
        }
    }
    elsif ($type eq 'ARRAY') {
        my $prev_is_array = ref($prev) eq 'ARRAY';
        my $prev_max = $prev_is_array ? $#$prev : -1;

        for my $i (0 .. $#$data) {
            next unless ref($data->[$i]) eq 'HASH' && exists $data->[$i]{'__ics__'};

            $data->[$i] = _decode_json_resolve(
                $data->[$i]{'__ics__'},
                $prev_is_array && $i <= $prev_max ? $prev->[$i] : undef,
                $knot,
            );
        }
    }
}
sub _decode_json_resolve {
    my ($info, $existing, $knot) = @_;

    if (defined $existing) {
        my $inner = ref($existing) && _is_child($existing);
        return $existing if $inner && $inner->{_key} == $info->{child_key};
    }

    return _decode_json_reattach($info, $knot);
}
sub _decode_json_reattach {
    my ($info, $knot) = @_;

    my %opts = (
        %{ $knot->attributes },
        key       => $info->{child_key},
        exclusive => 0,
        create    => 0,
        magic     => 1,
    );

    if ($info->{type} eq 'HASH') {
        my %h;
        tie %h, 'IPC::Shareable', \%opts;
        return \%h;
    }
    elsif ($info->{type} eq 'ARRAY') {
        my @a;
        tie @a, 'IPC::Shareable', \%opts;
        return \@a;
    }
    elsif ($info->{type} eq 'SCALAR') {
        my $s;
        tie $s, 'IPC::Shareable', \%opts;
        return \$s;
    }
}
sub _encode_verbatim {
    my ($seg, $val) = @_;

    # Store a plain scalar verbatim. Layout: the 14-byte 'IPC::Shareable' tag
    # (so shm_segments()/clean_up_testing still recognize the segment as ours),
    # a one-byte \x1e sentinel marking "not serialized — hand these bytes back
    # as-is", then the caller's bytes. The sentinel lets _decode tell this from
    # a json {…} body or a storable header. The caller (_encode) guarantees
    # $val is a defined, non-ref scalar.

    my $raw = "IPC::Shareable\x1e" . $val;

    if (length($raw) > $seg->size) {
        croak "Length of shared data exceeds shared segment size";
    }

    $seg->shmwrite($raw);
}
sub _decode_verbatim {
    my ($seg) = @_;

    # Recognize a verbatim scalar segment: the 14-byte 'IPC::Shareable' tag
    # followed by the \x1e sentinel. Return a scalar ref to the bytes after the
    # sentinel — trailing NUL padding stripped, internal NULs preserved. Return
    # undef for anything else (a json {…}/[…] body, a storable body, or an
    # empty/never-written segment) so _decode falls through to the serializer.

    my $raw = $seg->shmread;

    return if ! defined $raw;

    $raw =~ s/\x00+$//;

    return if substr($raw, 0, 15) ne "IPC::Shareable\x1e";

    my $payload = substr($raw, 15);

    return \$payload;
}
sub _freeze {
    my ($seg, $water) = @_;

    my $ice = freeze $water;

    croak "Could not serialize data for shared memory"
        unless defined $ice;

    substr $ice, 0, 0, 'IPC::Shareable';

    if (length($ice) > $seg->size) {
        croak "Length of shared data exceeds shared segment size";
    }

    $seg->shmwrite($ice);
}
sub _thaw {
    my ($seg) = @_;

    my $ice = $seg->shmread;

    return if ! $ice;

    my $tag = substr $ice, 0, 14, '';

    if ($tag eq 'IPC::Shareable') {
        my $water = thaw $ice;
        if (! defined($water)) {
            croak "Munged shared memory segment (size exceeded?)";
        }
        return $water;
    }
    else {
        return;
    }
}

# Data management

sub _tie {
    my ($type, $class, $key_str, $opts);

    if (scalar @_ == 4) {
        # Legacy API allowed a string scalar key
        ($type, $class, $key_str, $opts) = @_;
        $opts->{key} = $key_str;
    }
    else {
        ($type, $class, $opts) = @_;
    }

    $opts  = _parse_args($opts);

    my $knot = bless { attributes => $opts }, $class;

    $knot->uuid;

    my $key      = $knot->_shm_key;
    my $flags    = $knot->_shm_flags;
    my $shm_size = $knot->attributes('size');

    if ($knot->attributes('limit') && $shm_size > SHMMAX_BYTES) {
        croak
            "Shared memory segment size '$shm_size' is larger than max size of " .
            SHMMAX_BYTES;
    }

    my $seg;

    if ($knot->attributes('graceful')) {
        my $exclusive = eval {
            $seg = IPC::Shareable::SharedMem->new(
                key   => $key,
                size  => $shm_size,
                flags => $flags,
                mode  => $knot->attributes('mode'),
                type  => $type,
            );

            1;
        };

        if (! defined $exclusive) {
            if ($knot->attributes('warn')) {
                my $key = lc(sprintf("0x%X", $knot->_shm_key));

                warn "Process ID $$ exited due to exclusive shared memory collision at segment/semaphore key '$key'\n";
            }
            exit(0);
        }
    }
    else {
        $seg = IPC::Shareable::SharedMem->new(
            key   => $key,
            size  => $shm_size,
            flags => $flags,
            mode  => $knot->attributes('mode'),
            type  => $type,
        );
    }

    if (! defined $seg) {
        if ($!{ENOMEM}) {
            croak "\nERROR: Could not create shared memory segment: $!\n\n" .
                  "Are you using too large a segment size, or spawning too many segments?";
        }

        if ($!{ENOSPC}) {
            croak "\nERROR: Could not create shared memory segment: $!\n\n" .
                "Are you spawning too many segments (in a loop perhaps)?";
        }

        if (! $knot->attributes('create')) {
            confess "ERROR: Could not acquire shared memory segment... 'create' ".
                  "option is not set, and the segment hasn't been created " .
                  "yet:\n\n $!";
        }
        elsif ($knot->attributes('create') && $knot->attributes('exclusive')) {
            croak "ERROR: Could not create shared memory segment. 'create' " .
                  "and 'exclusive' are set. Does the segment already exist? " .
                  "\n\n$!";
        }
        else {
            croak "ERROR: Could not create shared memory segment.\n\n$!";
        }
    }

    # Try to attach to an existing semaphore set first using nsems=0, which
    # avoids EINVAL on macOS/BSD when the existing set has fewer slots than
    # the requested count. If the set does not exist yet, fall through to
    # create a new semaphore set: 5 slots when the 'testing' attribute is set
    # (adds SEM_TESTING at index 4), 4 slots otherwise.

    my $nsems = $knot->attributes('testing') ? 5 : 4;

    my $sem = IPC::Semaphore->new($key, 0, $seg->flags & 0777)
           // IPC::Semaphore->new($key, $nsems, $seg->flags);

    if (! defined $sem) {
        # The segment was created just above, but we couldn't establish its
        # semaphore set (eg. ENOSPC when the host's semaphore limit is hit).
        # Remove the segment we just made so it isn't orphaned -- but only when
        # we are the creator: a pure attacher (create => 0) must never remove a
        # segment that another process owns. An IPC_PRIVATE segment is always
        # freshly created by shmget() regardless of the 'create' attribute, and
        # is unreachable by key once we croak, so it must be removed too -- it
        # would otherwise leak invisibly (clean_up_testing() cannot see key 0).
        # Preserve $! across the removal so the croak still reports the
        # original failure (eg. "No space left on device") rather than the
        # result of the cleanup's shmctl.

        my $err = $!;

        $seg->remove if $knot->attributes('create') || $key == IPC_PRIVATE;
        $! = $err;

        croak "Could not create semaphore set: $!\n";
    }

    if (! $sem->op(@{ $semop_args{(LOCK_SH)} }) ) {
        # Lock acquisition failed before the knot was registered, so nothing
        # else will reclaim these. Tear down what we just made: the semaphore
        # set if we created it (its marker isn't set yet), and the segment if
        # we are its creator (an IPC_PRIVATE segment is always freshly created,
        # and unreachable by key hereafter, so it counts as ours too).
        # Preserve $! so the croak still names the cause.

        my $err = $!;

        $sem->remove if $sem->getval(SEM_MARKER) != SHM_EXISTS;
        $seg->remove if $knot->attributes('create') || $key == IPC_PRIVATE;
        $! = $err;

        croak "Could not obtain semaphore set lock: $!\n";
    }

    %$knot = (
        %$knot,
        _hkey_list          => undef,
        _key                => $key,
        _key_hex            => $seg->key_hex,
        _lock               => 0,
        _shm                => $seg,
        _sem                => $sem,
        _type               => $type,
        _type_int           => $type eq 'HASH' ? TYPE_HASH : $type eq 'ARRAY' ? TYPE_ARRAY : TYPE_SCALAR,
        _was_changed        => 0,
    );

    my $serializer = $knot->attributes('serializer');

    if ($serializer eq 'json') {
        my $data;
        my $decoded_ok = eval { $data = $knot->_decode($seg); 1 };

        if (! $decoded_ok) {
            # JSON decode threw; the segment may contain legacy Storable data.
            # Try Storable; if it succeeds, silently switch this session over
            # and warn the caller so they know to migrate.

            my $storable_data;
            my $thaw_ok = eval { $storable_data = _thaw($seg); 1 };

            if ($thaw_ok && defined $storable_data) {
                carp sprintf(
                    "IPC::Shareable: segment 0x%08x contains Storable-encoded data; "
                  . "switching serializer to 'storable' for this session. "
                  . "Re-create the segment to migrate it to JSON.",
                    $key
                );
                $knot->{attributes}{serializer} = 'storable';
                $knot->{_data} = $storable_data;
            }
            else {
                die $@;
            }
        }
        else {
            $knot->{_data} = $data;
        }
    }
    else {
        $knot->{_data} = $knot->_decode($seg);
    }

    # Register unconditionally so any process that attaches to an existing
    # segment (create=>0, re-attach, cross-process) is also tracked for
    # clean_up_all(). Previously only new segments were registered here,
    # requiring the Dumper hack in global_register() to catch the rest

    if (! exists $global_register{$knot->seg->id}) {
        $global_register{$knot->seg->id} = $knot;
    }

    if ($sem->getval(SEM_MARKER) != SHM_EXISTS) {

        $process_register{$knot->seg->id} ||= $knot;

        $sem->setval(SEM_PROTECTED, $knot->attributes('protected'));

        if ($knot->attributes('testing')) {
            $sem->setval(SEM_TESTING, _testing_semaphore_key_hash($knot->attributes('testing')));
        }

        if (! $sem->setval(SEM_MARKER, SHM_EXISTS)) {
            croak "Couldn't set semaphore during object creation: $!";
        }
    }
    else {
        # Segment already existed — restore the protected and testing
        # attributes from the semaphore so that clean_up_all() / clean_up_testing()
        # in this process work correctly even when the caller did not explicitly
        # pass them on tie.

        my $stored_protected = $sem->getval(SEM_PROTECTED);

        if (defined $stored_protected && $stored_protected != 0) {
            $knot->{attributes}{protected} = $stored_protected
        }

        my $stored_testing = _testing_semaphore_value($sem);

        if ($stored_testing) {
            $knot->{attributes}{testing} = $stored_testing;
        }
    }

    $sem->op(@{ $semop_args{(LOCK_SH|LOCK_UN)} });

    return $knot;
}
sub _magic_tie {
    my ($parent, $val) = @_;

    my $key;

    if ($parent->{_key} == IPC_PRIVATE && $parent->attributes('serializer') ne 'json') {
        $key = IPC_PRIVATE;
    }
    else {
        $key = _shm_key_rand();
    }

    # The individual options in the hash override any pre-set options that are
    # being inherited from the parent

    my %opts = (
        %{ $parent->attributes },
        key       => $key,
        exclusive => 1,
        create    => 1,
        magic     => 1,
    );

    # XXX I wish I didn't have to take a copy of data here and copy it back in
    # XXX Also, have to peek inside potential objects to see their implementation

    my $child;
    my $type = Scalar::Util::reftype($val) || '';

    if ($type eq "HASH") {
        my %copy = %$val;
        $child = tie %$val, 'IPC::Shareable', $key, { %opts };
        croak "Could not create inner tie" if ! $child;

        %$val = %copy;
    }
    elsif ($type eq "ARRAY") {
        my @copy = @$val;
        $child = tie @$val, 'IPC::Shareable', $key, { %opts };
        croak "Could not create inner tie" if ! $child;

        @$val = @copy;
    }
    elsif ($type eq "SCALAR") {
        my $copy = $$val;
        $child = tie $$val, 'IPC::Shareable', $key, { %opts };
        croak "Could not create inner tie" if ! $child;

        $$val = $copy;
    }
    else {
        croak "Variables of type $type not implemented";
    }

    return $child;
}
sub _need_tie {
    my ($knot, $val) = @_;

    my $type = Scalar::Util::reftype($val);
    return 0 if ! $type;

    my $need_tie;

    if ($type eq "HASH") {
        $need_tie = ! (tied %$val);
    }
    elsif ($type eq "ARRAY") {
        $need_tie = ! (tied @$val);
    }
    elsif ($type eq "SCALAR") {
        $need_tie = ! (tied $$val);
    }

    return $need_tie ? 1 : 0;
}
sub _remove_child {
    my ($val) = @_;

    if (ref($val) && (my $child = _is_child($val))) {
        $child->remove;
    }
}
sub _is_child {
    return $_have_xs
        ? _is_child_xs($_[0])
        : _is_child_pp($_[0]);
}
sub _is_child_pp {
    my $data = shift or return;

    my $type = Scalar::Util::reftype( $data );
    return unless $type;

    my $obj;

    if ($type eq "HASH") {
        $obj = tied %$data;
    }
    elsif ($type eq "ARRAY") {
        $obj = tied @$data;
    }
    elsif ($type eq "SCALAR") {
        $obj = tied $$data;
    }

    if (ref $obj eq 'IPC::Shareable') {
        return $obj;
    }

    return;
}
sub _write_to_seg {
    my ($knot) = @_;

    my $seg_id = $knot->seg->id;

    if (! defined $knot->_encode($knot->seg, $knot->{_data})) {
        croak "Could not write to shared memory segment $seg_id: $!";
    }
}

# Segment/semaphore operations

sub _execute_lock_coderef {
    my ($knot, $code) = @_;

    my $ok = eval { $code->(); 1 };
    my $err = $@;

    $knot->unlock;

    die $err if ! $ok;
}
sub _key_str_to_int {
    # Convert any key format (hex string, decimal integer string, or arbitrary
    # text) to a 32-bit integer using the same algorithm as _shm_key(), but
    # without the %used_ids side effect. Safe to call any number of times.

    my ($key_str) = @_;

    return hex($key_str)    if $key_str =~ /^0x[0-9a-fA-F]+$/i;
    return $key_str + 0     if $key_str =~ /^\d+$/;

    my $int = crc32($key_str);
    $int -= MAX_KEY_INT_SIZE if $int > MAX_KEY_INT_SIZE;
    return $int;
}
sub _lock_children {
    my ($root_knot, $flags) = @_;

    my @locked;

    my %seen = ($root_knot->seg->id => 1);
    my @stack = ([$root_knot, 0]);

    while (@stack) {
        my $frame = $stack[-1];
        my ($knot, $idx) = @$frame;

        my $data  = $knot->{_data};
        my $rtype = Scalar::Util::reftype($data) // '';

        my @vals = $rtype eq 'HASH'  ? values %$data
                 : $rtype eq 'ARRAY' ? @$data
                 : ();

        my $found = 0;

        for (my $i = $idx; $i < @vals; $i++) {

            my $val = $vals[$i];
            next unless ref($val);

            my $child = _is_child($val);
            next unless $child && $child->seg;

            my $id = $child->seg->id;
            next if $seen{$id}++;

            if (! $child->sem->op(@{ $semop_args{$flags} })) {
                for my $locked (reverse @locked) {
                    my $rflags = $locked->{_lock} | LOCK_UN;
                    $rflags ^= LOCK_NB if $rflags & LOCK_NB;
                    $locked->sem->op(@{ $semop_args{$rflags} });
                    $locked->{_lock} = 0;
                }
                return;
            }

            $child->{_data} = $child->_decode($child->seg);
            $child->{_lock} = $flags;

            push @locked, $child;

            $frame->[1] = $i + 1;

            push @stack, [$child, 0];

            $found = 1;

            last;
        }

        pop @stack unless $found;
    }

    return \@locked;
}
sub _shm_data_summary {
    my ($knot) = @_;

    my $data  = $knot->{_data};
    my $rtype = Scalar::Util::reftype($data) // '';

    if ($rtype eq 'SCALAR') {
        my $v = $$data;
        return defined $v ? qq("$v") : '(undef)';
    }

    if ($rtype eq 'HASH') {
        my @parts;
        for my $k (sort keys %$data) {
            my $v = $data->{$k};
            if (ref $v) {
                my $vt    = Scalar::Util::reftype($v) // '';
                my $child = $vt eq 'HASH'   ? tied(%$v)
                    : $vt eq 'ARRAY'  ? tied(@$v)
                    : $vt eq 'SCALAR' ? tied($$v)
                    : undef;
                push @parts, $child && $child->{_key_hex}
                    ? qq($k => <child: $child->{_key_hex}>)
                    : "$k => <ref>";
            }
            else {
                push @parts, defined $v ? qq($k => "$v") : "$k => (undef)";
            }
        }
        return @parts ? '{ ' . join(', ', @parts) . ' }' : '{}';
    }

    if ($rtype eq 'ARRAY') {
        my @parts;
        for my $v (@$data) {
            if (ref $v) {
                my $vt    = Scalar::Util::reftype($v) // '';
                my $child = $vt eq 'HASH'   ? tied(%$v)
                    : $vt eq 'ARRAY'  ? tied(@$v)
                    : $vt eq 'SCALAR' ? tied($$v)
                    : undef;
                push @parts, $child && $child->{_key_hex}
                    ? "<child: $child->{_key_hex}>"
                    : '<ref>';
            }
            else {
                push @parts, defined $v ? qq("$v") : '(undef)';
            }
        }
        return '[' . join(', ', @parts) . ']';
    }

    return '(unknown type)';
}
sub _shm_flags {
    # Parses the anonymous hash passed to constructors; returns a list
    # of args suitable for passing to shmget

    my ($knot) = @_;

    my $flags = 0;

    $flags |= IPC_CREAT if $knot->attributes('create');
    $flags |= IPC_EXCL  if $knot->attributes('exclusive');

    return $flags;
}
sub _shm_key {
    # Generates a 32-bit CRC on the key string. The $key_str parameter is used
    # for testing only, for purposes of testing various key strings

    my ($knot, $key_str) = @_;

    $key_str //= ($knot->attributes('key') || '');

    my $key;

    if ($key_str eq '') {
        $key = IPC_PRIVATE;
    }
    elsif ($key_str =~ /^0x[0-9a-fA-F]+$/i) {
        # User specified an explicit hex string key (eg. '0xDEADBEEF'); use the
        
        # bit pattern as-is so the segment key seen by ipcs(1) matches exactly.
        $key = hex($key_str);
        $used_ids{$key}++;
        return $key;
    }
    elsif ($key_str =~ /^\d+$/) {
        # User specified an explicit decimal integer key; use it as-is.
        $key = $key_str;
        $used_ids{$key}++;
        return $key;
    }
    else {
        # String key: compute a 32-bit CRC and apply overflow correction so the
        # result fits in a signed 32-bit key_t.
        $key = crc32($key_str);
    }

    $used_ids{$key}++;

    if ($key >= MAX_KEY_INT_SIZE) {
        $key = $key - MAX_KEY_INT_SIZE;

        if ($key == 0) {
            croak "We've calculated a key which equals 0. This is a fatal error";
        }
    }

    return $key;
}
sub _shm_key_rand {
    my $key;

    # Unfortunately, the only way I know how to check if a segment exists is
    # to actually create it. We must do that here, then remove it just to
    # ensure the slot is available

    my $verified_exclusive = 0;

    my $check_count = 0;

    while (! $verified_exclusive && $check_count < EXCLUSIVE_CHECK_LIMIT) {
        $check_count++;

        $key = _shm_key_rand_int();

        next if $used_ids{$key};

        my $flags;
        $flags |= IPC_CREAT;
        $flags |= IPC_EXCL;

        my $seg;

        my $shm_slot_available = eval {
            $seg = IPC::Shareable::SharedMem->new(
                key     => $key,
                size    => 1,
                flags   => $flags,
            );

            1;
        };

        if ($shm_slot_available) {
            $verified_exclusive = 1;
            $seg->remove if $seg;
        }
    }

    if (! $verified_exclusive) {
        croak
            "_shm_key_rand() can't get an available key after $check_count tries";
    }

    $used_ids{$key}++;

    return $key;
}
sub _shm_key_rand_int {
    return int(rand(1_000_000));
}
sub _read_check {
    my ($knot) = @_;

    # Advisory only: never blocks the read, only warns. Called from FETCH
    # when this knot is unlocked (a locked FETCH uses _data cache and never
    # touches shmem). Race window exists between this getval() and the
    # subsequent _decode() — a writer could acquire in between — but this
    # still catches the common case where a reader forgot to lock.

    return unless $knot->attributes('enforced_read_locking');
    return unless $knot->attributes('violated_read_lock_warn');

    # getval() can return undef if the semaphore set has been removed (eg.
    # after clean_up_all). The check is advisory only, so silently skip when
    # the semaphore is no longer reachable.

    my $writers = $knot->sem->getval(SEM_WRITERS);
    return unless defined $writers;

    if ($writers > 0) {
        my $uuid   = $knot->uuid;
        my $seg_id = $knot->seg->id;

        warn "Object with UUID $uuid attempted read from segment ID "
            . "$seg_id which is exclusively locked (enforced read locking "
            . "enabled); returned data may be stale or partially-written. "
            . "Acquire LOCK_SH before reading to guarantee a coherent snapshot";
    }

    return;
}
sub _write_permitted {
    my ($knot) = @_;

    return 1 unless $knot->attributes('enforced_write_locking');

    # If this knot itself holds LOCK_EX it is the owner of the lock and is
    # permitted to write.

    return 1 if $knot->{_lock} & LOCK_EX;

    my $sem = $knot->sem;

    # Semaphore index 2 is the write-lock counter; it is 1 when any other knot
    # holds LOCK_EX (set via SEM_UNDO so it auto-releases on process exit).

    # getval() returns undef if the semaphore set has been removed by another
    # process (eg. clean_up_all, or a peer with destroy=>1 exiting). The
    # enforcement check is advisory, so when the set is unreachable we skip it
    # and permit the write, mirroring _check_read_lock().

    # Block if any process holds LOCK_EX

    my $writers = $sem->getval(SEM_WRITERS);
    return 1 if ! defined $writers;

    if ($writers > 0) {
        if ($knot->attributes('violated_write_lock_warn')) {
            my $uuid   = $knot->uuid;
            my $seg_id = $knot->seg->id;

            warn "Object with UUID $uuid attempted write to segment ID "
                . "$seg_id which is exclusively locked (enforced write "
                . "locking enabled). Your write was not accepted. Lock with "
                . "LOCK_EX to ensure successful writes when a segment is "
                . "already locked";
        }

        return 0;
    }

    # Block if any process holds LOCK_SH (active readers present)

    my $readers = $sem->getval(SEM_READERS);
    return 1 if ! defined $readers;

    if ($readers > 0) {
        if ($knot->attributes('violated_write_lock_warn')) {
            my $uuid   = $knot->uuid;
            my $seg_id = $knot->seg->id;

            warn "Object with UUID $uuid attempted write to segment ID "
                . "$seg_id which has active readers (enforced write locking "
                . "enabled)";
        }

        return 0;
    }

    return 1;
}

# Unit testing support

sub _testing_semaphore_key_hash {
    my ($dist_name) = @_;

    # SysV SEMVMX caps semaphore values at 32767 on most platforms (incl.
    # macOS, BSD); mask the CRC32 to 15 bits so setval() never silently fails.
    # 0 is reserved to mean "not a testing segment", so we shift any zero
    # collision off slot 0.

    my $h = String::CRC32::crc32($dist_name) & 0x7FFF;

    return $h || 1;
}
sub _testing_semaphore_value {
    my ($sem) = @_;

    my $stat = $sem->stat or return 0;

    return 0 if $stat->nsems < 5;
    return $sem->getval(SEM_TESTING) // 0;
}

# Misc

sub _parse_args {
    my ($opts) = @_;

    $opts  = defined $opts  ? $opts  : { %default_options };

    # Note caller's explicit intent BEFORE defaults are merged in. A caller
    # who passes testing => 0 wants to opt out of auto-tagging; we must not
    # treat that as "absent" after defaulting.

    my $testing_explicit = exists $opts->{testing};

    for my $k (keys %default_options) {
        if (not defined $opts->{$k}) {
            $opts->{$k} = $default_options{$k};
        }
        elsif ($opts->{$k} eq 'no') {
            if ($^W) {
                require Carp;
                Carp::carp("Use of `no' in IPC::Shareable args is obsolete");
            }

            $opts->{$k} = 0;
        }
    }

    # Validate the serializer selection. 'json' (default) and 'storable' are the
    # only user-selectable options

    my $serializer = $opts->{serializer};

    if ($serializer ne 'json' && $serializer ne 'storable') {
        croak "Invalid 'serializer' value '$serializer'; must be 'json' or 'storable'";
    }

    $opts->{owner} = ($opts->{owner} or $$);
    $opts->{magic} = ($opts->{magic} or 0);

    # Inherit the process-level testing tag set by testing_set(), unless the
    # caller explicitly passed a testing value (including testing => 0)

    if ($_testing_dist && ! $testing_explicit) {
        $opts->{testing} = $_testing_dist;
    }

    return $opts;
}
sub _end {
    for my $s (values %process_register) {
        eval { unlock($s) };
        next if $s->attributes('protected');
        next if ! $s->attributes('destroy');
        next if $s->attributes('owner') != $$;
        eval { remove($s) };
    }
}

END {
    _end();
}

sub _placeholder {}

1;

__END__

=head1 NAME

IPC::Shareable - Use shared memory backed variables across processes

=for html
<a href="https://github.com/stevieb9/ipc-shareable/actions"><img src="https://github.com/stevieb9/ipc-shareable/workflows/CI/badge.svg"/></a>
<a href='https://coveralls.io/github/stevieb9/ipc-shareable?branch=master'><img src='https://coveralls.io/repos/stevieb9/ipc-shareable/badge.svg?branch=master&service=github' alt='Coverage Status' /></a>

=head1 SYNOPSIS

    use IPC::Shareable qw(:lock);

    tie my %hash,   'IPC::Shareable', OPTIONS;
    tie my @array,  'IPC::Shareable', OPTIONS;
    tie my $scalar, 'IPC::Shareable', OPTIONS;

    # Lock, make changes, unlock

    tied(VARIABLE)->lock;
        # Do something with the variable
    tied(VARIABLE)->unlock;

    # Blocking lock attempt (a writer must have a LOCK_EX lock)

    tied(VARIABLE)->lock(LOCK_SH);
    my $val = VARIABLE->[5]; # Will wait to get value until writer releases LOCK_EX

    # Non-blocking lock attempt

    tied(VARIABLE)->lock(LOCK_SH|LOCK_NB)
        or print "Resource unavailable\n";

    # Lock with a code reference, which will auto-unlock when the block finishes

    tied(VARIABLE)->lock(sub { print "hello!\n"; });

    # Ensure only one instance of a script can be run at any time

    IPC::Shareable->singleton('UNIQUE SCRIPT LOCK STRING');


=head1 SYNOPSIS - DEVELOPER/TROUBLESHOOTING

    # Get SYSV shared memory specifications of the system (if available)

    my $href = IPC::Shareable::sysv_info();

    # Get the shared memory segment and semaphore objects directly

    my $segment   = tied(VARIABLE)->seg;
    my $semaphore = tied(VARIABLE)->sem;

    # Get the shared memory segment and semaphores for a lower level

    my $seg = tied(%{ $hv{a}->{b} })->seg;
    my $sem = tied(%{ $hv{a}->{b} })->sem;

    # Fetch a printable string representation of the segment and semaphore
    # mapping for your data

    my $shm_map = tied(VARIABLE)->seg_map;

    # Remove the shared memory segment and semaphore directly

    tied(VARIABLE)->remove;

    # Manual cleanup procedures (mainly used for unit testing etc)

    IPC::Shareable::clean_up;
    IPC::Shareable::clean_up_all;
    IPC::Shareable::clean_up_protected;

    # In the first test file that runs, purge any leaked segments that remain

    IPC::Shareable::clean_up_testing('My::Distribution');

    # Then in every test file that ties a segment, add:

    IPC::Shareable->testing_set('My::Distribution');

    # Get the actual IPC::Shareable tied object you can make method calls on
    # instead of using the tied object like the examples above

    my $knot = tied(VARIABLE); # Dereference first if using a tied reference

    # ...or get the knot at inception

    my $knot = tie my VARIABLE, 'IPC::Shareable', OPTIONS;
    my $sysv_info_href = $knot->sysv_info;


=head1 DESCRIPTION

IPC::Shareable allows you to tie a variable to shared memory, making it
easy to share the contents of that variable with other Perl processes and
scripts.

Scalars, arrays, hashes and even objects can be tied. The variable being
tied may contain arbitrarily complex data structures - including references to
arrays, hashes of hashes, etc.

B<Note>: When using nested data structures, each nested structure utilizes an
additional shared memory segment. The entire structure is not squashed into a
single segment. See L</DATA AND SEGMENT MAPPING> for details.

The association between variables in distinct processes is provided by
GLUE (aka. a "key"). This is any arbitrary string or integer that serves as a
common identifier for data across process space.  Hence the statement:

    tie my %hash, 'IPC::Shareable', { key => 'GLUE STRING', create => 1 };

...in program one and the statement

    tie my %thing, 'IPC::Shareable', { key => 'GLUE STRING' };

...in program two will create and bind C<%hash> the shared memory in program
one and bind it to C<%thing> in program two.

There is no pre-set limit to the number of processes that can bind to
data; nor is there a pre-set limit to the complexity of the underlying
data of the tied variables.  The amount of data that can be shared within a
single bound variable is limited by the system's maximum size for a shared
memory segment, and the total number of segments allowed by the system (the
exact values are system-dependent).

The bound data structures are all linearized (using L<JSON> by default or
optionally L<Storable>) before being slurped into shared memory. Upon retrieval,
the original format of the data structure is recovered. Semaphore flags can be
used for locking data between competing processes.

B<Tied scalars>: A tied scalar can store arbitrary data. If you send in plain
data, you get plain data back; if you encode it yourself (eg. with L<JSON>), it
is up to you to decode it. Storing a B<reference> shares the referenced
structure, the same as tying a hash or array.

B<Recommendation>: Utilizing the locking mechanisms is highly advised to ensure
data consistency and integrity. See L</LOCKING>.

B<Recommendation>: If you're using JSON to serialize your data (the default), I
would highly advise you to install the XS version (L<JSON::XS>). We will
automatically use it if available, and it is much faster than the pure Perl
version (L<JSON::PP>).


=head1 OPTIONS

Options are specified by passing a reference to a hash as the third argument to
the C<tie()> function that binds a variable. We also call these
B<attributes>.

The following fields are recognized in the options hash:

=head2 key

B<key> is the GLUE that is a direct reference to the shared memory segment
that's to be tied to the variable.

If this option is missing, we'll default to using C<IPC_PRIVATE>. Note however,
that going this route will not allow you to share your data across processes.

The key can be specified as:

=over 4

=item * A text string (internally, a 32-bit CRC of the string is used as the key)

=item * A hex string (eg. C<'0xDEADBEEF'>), which we convert to integer form

=item * A hex value (eg. C<0xDEADBEEF>), used as-is as the integer key

=item * An integer (eg. C<1234>), used as-is as the integer key

=back

Default: B<IPC_PRIVATE>

=head2 create

B<create> is used to control whether the process creates a new shared
memory segment or not.  If B<create> is set to a true value,
L<IPC::Shareable> will create a new binding associated with GLUE as needed.
If B<create> is false, L<IPC::Shareable> will not attempt to create a new shared
memory segment associated with GLUE.  In this case, a shared memory segment
associated with GLUE must already exist or we'll C<croak()>.

Default: B<false>

=head2 exclusive

If B<exclusive> field is set to a true value, we will C<croak()> if the data
binding associated with GLUE already exists.  If set to a false value, calls to
C<tie()> will succeed even if a shared memory segment associated with GLUE
already exists.

See L</graceful> for a silent, non-exception exit if a second process attempts
to obtain an in-use C<exclusive> segment.

Default: B<false>

=head2 graceful

If B<exclusive> is set to a true value, we normally C<croak()> if a second
process attempts to obtain the same shared memory segment. Set B<graceful>
to true and we'll C<exit> silently and gracefully. This option does nothing
if C<exclusive> isn't set.

See L</warn> to emit a warning before gracefully exiting when a collision occurs.

Default: B<false>

=head2 warn

When set to a true value, B<graceful> will output a warning if there are
process collisions.

Default: B<false>

=head2 mode

The B<mode> argument is an octal number specifying the access permissions when a
new data binding is being created.  These access permission are the same as file
access permissions in that C<0666> is world readable and writable, C<0600> is
writable only by the effective UID of the process creating the shared variable,
etc.

Default: B<0666> (world readable and writeable)

=head2 size

This field is used to specify the size (in bytes) of each shared memory segment
allocated.

B<Note>: Each nested data structure requires a new shared memory segment. The
C<size> attribute is applied to the first, and all subsequent segments created,
and does not reflect the overall size of memory to be used.

The maximum size we allow for each segment by default is ~1GB. See the L</limit>
option to override this default.

Default: C<IPC::Shareable::SHM_BUFSIZ()> (ie. B<65,536> bytes)

=head2 protected

The segments with this option set will persist even through all of our automatic
and manual clean up procedures, less
L<clean_up_protected|/clean_up_protected($protect_key)>.

Set this to a non-zero integer. The integer is persisted in the segment's
associated semaphore set, so any process that later attaches to the same
segment via C<< create => 0 >> will automatically have this attribute restored;
it does not need to pass C<< protected >> explicitly.

The integer acts as a group key: all segments (including nested children)
created under the same protected parent share the same value, so a single call
to C<clean_up_protected($key)> removes the entire group.

To clean up protected objects, call
C<< (tied %object)->clean_up_protected(integer) >>, where 'integer' is the
value you set the C<protected> option to. You can call this cleanup routine in
the script you created the segment, or anywhere else, at any time.

B<Note>: The protect key is limited to values accepted by the system's semaphore
implementation (typically 0-32767; 0 means unprotected).

Default: B<0>

=head2 testing

Set this to a non-empty string (conventionally the distribution name, e.g.
C<'IPC::Shareable'>) to brand the segment as belonging to a particular test
suite. At segment-creation time the CRC32 hash of the string is stored in a
fifth semaphore slot (C<SEM_TESTING>). This makes it possible for
L</clean_up_testing($dist_name)> to find and remove every such segment
system-wide -- including orphans from previous crashed runs -- without needing
them to be in C<%global_register>.

The integer hash (not the original string) is persisted in the semaphore set.
When a process re-attaches to a segment that was created with C<testing>, the
stored integer is restored into C<< attributes('testing') >>.

Rather than setting C<testing> on every individual C<tie()>, call
L</testing_set($dist_name)> once at the top of the test file; all subsequent
ties in that process (and in forked children spawned after the call) inherit it
automatically.

Default: B<0> (disabled)

=head2 limit

This field will allow you to set a segment size larger than the default maximum
which is 1,073,741,824 bytes (approximately 1 GB). If set, we will
C<croak()> if a size specified is larger than the maximum. If it's set to a
false value, we'll C<croak()> if you send in a size larger than the total
system RAM.

Default: B<true>

=head2 destroy

If set to a true value, the shared memory segment underlying the data
binding will be removed when the process that initialized the shared memory
segment exits cleanly.

Only those memory segments that were created by the current process will be
removed.

Use this option with care. In particular you should not use this option in a
program that will fork after binding the data.  On the other hand, shared memory
is a finite resource and should be released if it is not needed.

B<Note>: If the segment was created with its L</protected> attribute set,
it will not be removed upon program completion, even if C<destroy> is set.

Default: B<false>

=head2 serializer

By default, we use L<JSON> as the data serializer when writing to or
reading from the shared memory segments we create. For cross-platform and
cross-language interoperability this is the recommended choice. Alternatively,
you can use L<Storable> for richer data type support (eg. blessed objects).

Send in either C<json> or C<storable> as the value to use the respective
serializer.

Default: B<json>

=head2 enforced_write_locking

When enabled, writes from any knot are blocked while another knot holds
C<LOCK_EX> on the segment, or while there are active C<LOCK_SH> readers. Pair
with C<violated_write_lock_warn> to also emit a warning when a write is
blocked.

B<Note>: This protection system will never be reached if all callers use
proper locking at all times.

Default: B<true>

=head2 violated_write_lock_warn

When C<enforced_write_locking> is enabled, and this attribute is set to true,
we will emit a warning when a write violation occurs (a write attempted
against a segment that another knot has locked with C<LOCK_EX>, or a write
attempted against a segment with active C<LOCK_SH> readers). The warning
includes the UUID of the object that caused the violation and the segment ID
it occurred against.

Default: B<true>

=head2 enforced_read_locking

When enabled, an unlocked read against a segment that another knot has locked
with C<LOCK_EX> is detected. Reads are never B<blocked>; this option only
controls whether the check fires. Pair with C<violated_read_lock_warn> to emit
a warning when this happens.

B<Note>: Reads (fetches) are never blocked, even when a C<LOCK_EX> is active.
If a reader does not hold a C<LOCK_SH> and reads while a writer holds
C<LOCK_EX>, the returned data may be stale or partially-written. To guarantee
a coherent snapshot, acquire C<LOCK_SH> before reading.

B<Note>: This protection system will never be reached if all callers use
proper locking at all times.

Default: B<true>

=head2 violated_read_lock_warn

When C<enforced_read_locking> is enabled, and this attribute is set to true,
we will emit a warning when an unlocked read is attempted against a segment
that another knot has locked with C<LOCK_EX>. The returned data may be stale
or partially-written; the warning recommends acquiring C<LOCK_SH> before
reading to guarantee a coherent snapshot. The warning includes the UUID of
the object that caused the violation and the segment ID it occurred against.

Default: B<true>

=head2 Default Option Values

Default values for options are:

    key                         => IPC_PRIVATE, # 0
    create                      => 0,
    exclusive                   => 0,
    mode                        => 0666,
    size                        => IPC::Shareable::SHM_BUFSIZ(), # 65536
    protected                   => 0,
    testing                     => 0,
    limit                       => 1,
    destroy                     => 0,
    graceful                    => 0,
    warn                        => 0,
    serializer                  => 'json',
    enforced_write_locking      => 1,
    enforced_read_locking       => 1,
    violated_write_lock_warn    => 1,
    violated_read_lock_warn     => 1,


=head1 METHODS - STANDARD USER

These are typically the only methods a normal user will need in the course of
their use of this distribution.

=head2 new

This C<new()> call is not necessary and is a simple wrapper around C<tie()>. It
is capable only of returning a tied reference object (by default, a hash ref).

Instantiates and returns a reference to a hash backed by shared memory.

    my $href = IPC::Shareable->new(key => "testing", create => 1);

    $href->{a} = 1;

    # Call tied() on the dereferenced variable to access object methods
    # and information

    tied(%$href)->seg_count;

Parameters:

Optional: See the L</OPTIONS> section for a list of all available options.
Most often, you'll want to at minimum, send in the B<key> and B<create> options.

It is possible to get a reference to an array or scalar as well. Simply send in
either C<< var => 'ARRAY' >> or C<< var => 'SCALAR' >> to do so.

Return: A reference to a hash (or array or scalar) which is backed by shared
memory.

=head2 lock($flags, $code)

Obtains a lock on the shared memory. C<$flags> specifies the type of lock to
acquire.  If C<$flags> is not specified, an exclusive read/write lock is
obtained. Acceptable flags are:

    LOCK_EX         - Exclusive; use when writing
    LOCK_SH         - Shared; use when reading

    LOCK_EX|LOCK_NB - Exclusive, non-blocking
    LOCK_SH|LOCK_NB - Shared, non-blocking

Parameters:

    $flags

Optional, Integer: If this parameter is omitted, we default to C<LOCK_EX>, an
exclusive write lock.

    $code

Optional, Code reference: If this parameter is sent in, and an exclusive lock
is asked for, we will set the lock, execute the subroutine, and then call
C<unlock()> on the segment. The sub is called within an C<eval>, so we will
C<unlock>, then C<die> with whatever error your function threw.

B<Note>: Although the C<$flags> and C<$code> parameters appear positional, you
can send in C<$code> without sending in any C<$flags>. When this occurs,
C<$flags> will automatically be set to C<LOCK_EX>.

Return: C<true> on success, and C<undef> on error. For non-blocking calls, the
method returns C<0> if it would have blocked.

Obtain an exclusive lock like this:

        tied(%var)->lock(LOCK_EX); # Same as default

Only one process can hold an exclusive lock on the shared memory at a given
time.

Obtain a shared (read) lock:

        tied(%var)->lock(LOCK_SH);

Multiple processes can hold a shared (read) lock at a given time.  If a process
attempts to obtain an exclusive lock while one or more processes hold shared
locks, it will be blocked until they have all finished.

Either of the locks may be specified as non-blocking:

        tied(%var)->lock( LOCK_EX|LOCK_NB );
        tied(%var)->lock( LOCK_SH|LOCK_NB );

A non-blocking lock request will return C<0> immediately if it would have had to
wait to obtain the lock.

B<Note>: These locks are advisory (just like flock), meaning that all
cooperating processes must coordinate their accesses to shared memory using
these calls in order for locking to work.  See the C<flock()> call for details.

B<Note>: You can enforce a C<LOCK_EX> lock at a software level by ensuring that
the C<enforced_write_locking> option is set to a true value (the default).
This will prevent processes that decide not to implement the advisory locking
from writing to the segment. The companion C<enforced_read_locking> option
(also true by default) enables detection of unlocked reads against an
exclusively-locked segment; reads are never blocked, but a warning will be
emitted if C<violated_read_lock_warn> is also set.

B<Important>: Locks are inherited through forks, which can cause unintended and
problematic side effects (particularly duplicated C<LOCK_EX> locks). Don't
C<fork()> until all active locks have been released.

The constants C<LOCK_EX>, C<LOCK_SH>, C<LOCK_NB>, and C<LOCK_UN> are available
for import using any of the following export tags:

        use IPC::Shareable qw(:lock);
        use IPC::Shareable qw(:flock);
        use IPC::Shareable qw(:all);

Or, just use the C<flock> constants available in the C<Fcntl> module.

See L</LOCKING> for further details.

=head2 unlock

Removes a lock. Takes no parameters, returns C<true> on success.

This is equivalent to calling C<shlock(LOCK_UN)>.

See L</LOCKING> for further details.

=head2 singleton($glue, $warn)

Class method that ensures that only a single instance of a script can be run
at any given time.

Parameters:

    $glue

Mandatory, String: The key/glue that identifies the shared memory segment.

    $warn

Optional, Bool: Send in a true value to have subsequent processes throw a
warning that there's been a shared memory violation and that it will exit.

Default: B<false>

Return: C<$$>. The process ID.

B<Note>: See L<Script::Singleton|https://metacpan.org/pod/Script::Singleton>.
That library implements C<singleton> for a script with a simple C<use> line.


=head1 METHODS - OBJECT AND PROCESS

These methods provide facilities for identifying information about the current
object and the overall state information of the current processes.

=head2 attributes

Retrieves the list of attributes that drive the L<IPC::Shareable> object.

Attributes are the C<OPTIONS> that were used to create the object.

Parameters:

    $attribute

Optional, String: The name of the attribute. If sent in, we'll return the value
of this specific attribute. Returns C<undef> if the attribute isn't found.

Returns: A hash reference of all attributes if C<$attributes> isn't sent in, the
value of the specific attribute if it is.

=head2 global_register

Returns a hash reference of hashes of all in-use shared memory segments across
all processes/forks within the current process space. The key is the memory
segment ID, and the value is the segment and semaphore objects.

=head2 process_register

Returns a hash reference of hashes of all in-use shared memory segments created
by the calling process only (ie. not including forks). The key is the memory
segment ID, and the value is the segment and semaphore objects.

=head2 uuid

Returns the UUID of the object.


=head1 METHODS - MANUAL CLEANUP

These methods are mainly for forced cleanup. C<remove()> is used internally.
These methods are generally never needed by a normal user, and are primarily
for use in unit testing and other development work.

=head2 clean_up

    IPC::Shareable->clean_up;

    # or

    tied($var)->clean_up;

    # or

    $knot->clean_up;

This is a class method that provokes L<IPC::Shareable> to remove all
shared memory segments created by the process. Segments not created
by the calling process are not removed.

This method will not clean up segments created with the C<protected> option.

=head2 clean_up_all

    IPC::Shareable->clean_up_all;

    # or

    tied($var)->clean_up_all;

    # or

    $knot->clean_up_all

This is a class method that provokes L<IPC::Shareable> to remove all
shared memory segments encountered by the process. Segments are
removed even if they were not created by the calling process.

This method will not clean up segments created with the C<protected> option.

=head2 clean_up_protected($protect_key)

If a segment is created with the C<protected> option, it, nor its children will
be removed during calls of C<clean_up()> or C<clean_up_all()>.

When setting L</protected>, you specified a lock key integer. When calling this
method, you must send that integer in as a parameter so we know which segments
to clean up.

Because the protect key is stored in the segment's semaphore set, any process
that attached to the segment (even without passing C<< protected >> on tie)
will have had its in-process attribute populated automatically. You can
therefore call C<clean_up_protected()> from any process that has attached to
the segment, not only from the one that created it.

    my $protect_key = 93432;

    IPC::Shareable->clean_up_protected($protect_key);

    # or

    tied($var)->clean_up_protected($protect_key);

    # or

    $knot->clean_up_protected($protect_key)

Parameters:

    $protect_key

Mandatory, Integer: The integer protect key you assigned with the C<protected>
option

=head2 remove($key)

Parameters:

    $key

Optional, see L</key> for valid values. Preferably, an integer or a hex string
prefixed with C<0x>.

B<Note>: If the C<$key> parameter is sent in, we will delete that segment only
and return immediately thereafter.

    tied($var)->remove;

    # or

    $knot->remove;

    # Remove a specific segment by key (can remove non C<IPC::Shareable>
    # segments). If key is sent in, the caller can be the module or the object.

    IPC::Shareable->remove('0xdeadbeef');   # hex string
    IPC::Shareable->remove(0xdeadbeef);     # hex integer
    IPC::Shareable->remove(1234);           # integer
    tied($var)->remove('Test');             # string

B<Note>: Calling C<remove()> on the object underlying a C<tie()>d variable
removes the associated shared memory segment.  The segment is removed
irrespective of whether it has the B<destroy> option set or not and
irrespective of whether the calling process created the segment.


=head1 METHODS - SYSTEM AND SHARED MEMORY

These methods are for very low level diagnostic, troubleshooting, investigation,
informational and fact finding situations.

B<Note>: Both L</seg> and L</sem> are external objects and have their own
methods and data that can be used for analysis. This is particularly true with
L</seg>. Each of their respective documentation sections link to their
corresponding documentation.

=head2 seg

Called on either a tied variable or on the tie object, returns the shared
memory segment object currently in use.

    tie my %h, ...;
    $h{a}->{b}{c} = 10;

    my $top_level_seg = tied(%h)->seg;
    my $bot_level_seg = tied(%{ $h{a}->{b} })->seg;

See L<IPC::Shareable::SharedMem> documentation for details and available
methods.

=head2 sem

Called on either a tied variable or on the tie object, returns the semaphore
object related to the memory segment currently in use.

    tie my %h, ...;
    $h{a}->{b}{c} = 10;

    my $top_level_sem = tied(%h)->sem;
    my $bot_level_sem = tied(%{ $h{a}->{b} })->sem;

See L<IPC::Semaphore> documentation.

=head2 seg_count

Returns the number of shared memory segments that currently exist
on the system, by counting data lines in your system's C<ipcs -m> output.
It is guaranteed to produce consistent results.

Return: Integer

=head2 sem_count

Returns the number of semaphore sets that currently exist on the system, by
parsing C<ipcs -s>. Since each L<IPC::Shareable> segment is associated with
exactly one semaphore set (same SysV key), this count moves in lockstep with
L</seg_count> when L<IPC::Shareable> segments are the only semaphore
users on the system and are created and destroyed cleanly.

Return: Integer

=head2 shm_segments($key)

    my $ipc_shareable_segments = IPC::Shareable->shm_segments;

    # Filtered to one variable's segments only
    my $segs = IPC::Shareable->shm_segments('my_key');
    my $segs = IPC::Shareable->shm_segments('0xDEADBEEF');

Class/object method. Scans all existing shared memory segments on the system
and returns a hash reference mapping the hex key string (eg. C<'0xdeadbeef'>)
to the raw literal contents of that segment. Only loads segments that were
created by L<IPC::Shareable>.

Segments created with C<IPC_PRIVATE> (key C<0x00000000>) are skipped because
they cannot be looked up by key.

Parameters:

    $key

Optional, String or Int: If sent in, we will restrict the result to only the
segments related to the variable the C<$key> reflects. Without this parameter,
all L<IPC::Shareable> segments on the system are returned.

Return: Hash reference where each key is the SHM key in hex format.

Field descriptions:

B<known>: C<1> if this segment is currently tied in the calling process, C<0>
if not. A value of C<0> includes segments legitimately persisted by another
process (C<destroy =E<gt> 0>), not just crashed leftovers. See
L</unknown_segments> for important caveats.

B<local_process>: C<1> if created by the same process this method is being run,
and C<0> if not.

B<content>: The actual raw content of the shared memory segment.

B<child_keys>: Nested data structures each require their own segment. Keys
within this array reference map to child segments.

Here's an example data structure, and what the return value of C<shm_segments>
would look like for it using the JSON serializer. Note that the top-level
structure is a hash, and it contains two nested hashes (keys 'c' and 'd'), which
are each stored in their own segments. It also has two scalar values (keys 'a'
and 'b'), which are stored in the top-level segment.

    # Actual data

    {
        a => 1,
        b => 'hello',
        c => {
            x => 10,
            y => 20,
        },
        d => {
            p => 'foo',
            q => 'bar',
        },
    }

    # Call return (JSON content strings will be on one line; separated for
    # clarity)

    {
        '0x2abc0001' => {
            known           => 1,
            local_process   => 1,
            content         => 'IPC::Shareable{
                "a": 1,
                "b": "hello",
                "c": {
                    "__ics__": {
                        "child_key_hex": "0x000e1b1d",
                        "child_key":     "924445",
                        "type":          "HASH"
                    }
                },
                "d": {
                    "__ics__": {
                        "child_key_hex": "0x000097af",
                        "child_key":     "38831",
                        "type":          "HASH"
                    }
                }
            }',
            child_keys      => [
                '0x000e1b1d',
                '0x000097af'
            ],
        },
        '0x000e1b1d' => {
            known           => 1,
            local_process   => 1,
            content         => 'IPC::Shareable{"y":20,"x":10}',
            child_keys      => [],
        },
        '0x000097af' => {
            known           => 1,
            local_process   => 1,
            content         => 'IPC::Shareable{"p":"foo","q":"bar"}',
            child_keys      => [],
        }
    }

=head2 unknown_segments

    my @unknown_segments = IPC::Shareable->unknown_segments;

    for my $key (@unknown_segments) {
        print "Unknown segment: $key\n";
        IPC::Shareable->remove($key);
    }

Class/object method. Returns a list of hex key strings (eg. C<'0xdeadbeef'>)
for all shared memory segments that were created by L<IPC::Shareable> but are
not currently tied in the calling process.

B<Important>: this method has no way to distinguish between a segment that was
left behind by a crashed process and one that is legitimately persisted by
another running process (C<destroy =E<gt> 0>). Both will appear in the returned
list. Only call C<remove> on entries you are certain belong to your own
application and are no longer in use.

Return: List of hex key strings.

=head2 seg_map

    # Show all IPC::Shareable segments visible on the system
    print IPC::Shareable->seg_map;

    # Show only the segment tree rooted at this object
    print $knot->seg_map;
    print tied(%hash)->seg_map;

When called as a B<class method>, returns a human-readable string showing all
L<IPC::Shareable> shared memory segments visible on the current system,
organised as a tree (root segments at the top, nested children indented below
their parent).

When called as an B<object method>, the output is filtered to just the segment
tree rooted at that object (the segment itself plus any nested children).

For each segment the output includes:

=over 4

=item * The hex key and OS segment ID

=item * Status tags: C<known> (tied in this process) or C<unknown>, and
C<owner> if this process created the segment

=item * Semaphore information: OS semaphore ID (C<sem_id>), C<SEM_MARKER>,
read-lock counter, write-lock counter, and C<PROTECTED> (the integer stored
in C<SEM_PROTECTED>)

=item * The list of child segment hex keys, or C<(none)>

=item * The segment's current content. Reference values that are child segments
are shown as C<< <child: 0xHEX> >> rather than being recursed into.
Segments not tied in this process show C<(not accessible)>.

=back

Example:

    tie my %h, 'IPC::Shareable', {
        key     => 0x1a2b,
        create  => 1,
        destroy => 1
    };

    $h{nested} = { x => 1, y => 2 };

    my $mapping = tied(%h)->seg_map;

    print $mapping;

Output:

IPC::Shareable Segment Map
==========================

    [known, owner]  key: 0x00001a2b  seg_id: 1890844693
        Semaphores: sem_id: 1272774674
            1: SEM_MARKER=1
            2: READERS=0
            3: WRITERS=0
            4: PROTECTED=0
        Children:   0x00018373
        Content:    { nested => <child: 0x00018373> }

    [known, owner]  key: 0x00018373  seg_id: 1888682002
        Semaphores: sem_id: 1300234259
            1: SEM_MARKER=1
            2: READERS=0
            3: WRITERS=0
            4: PROTECTED=0
        Children:   (none)
        Content:    { x => "1", y => "2" }

=head2 sysv_info

    my $sysv_info = IPC::Shareable->sysv_info;

    print "Max segment size: $sysv_info->{shmmax}\n";
    print "Max segments (system): $sysv_info->{shmmni}\n";
    print "Max semaphore sets (system): $sysv_info->{semmni}\n";

Class method. Returns a hash reference containing the kernel's SysV shared
memory and semaphore configuration parameters for the current platform.

Returns C<undef> if the platform is not supported or no data could be read.

On MacOS, reads from C<sysctl kern.sysv>. Example return value:

    {
        shmmax => 4194304,   # Maximum size of a single segment (bytes)
        shmmin => 1,         # Minimum size of a single segment (bytes)
        shmmni => 32,        # Maximum number of segments system-wide
        shmseg => 8,         # Maximum number of segments per process
        shmall => 1024,      # Maximum total shared memory (pages)
        semmni => 87381,     # Maximum number of semaphore identifier sets
        semmns => 87381,     # Maximum semaphores system-wide
        semmsl => 87381,     # Maximum semaphores per set
    }

On Linux, reads from C</proc/sys/kernel/>. Example return value:

    {
        shmmax => 18446744073692774399,  # Maximum size of a single segment (bytes)
        shmmin => 1,                     # Minimum size of a single segment (bytes)
        shmmni => 4096,                  # Maximum number of segments system-wide
        shmall => 18446744073692774399,  # Maximum total shared memory (pages)
        semmsl => 32000,                 # Maximum semaphores per set
        semmns => 1024000000,            # Maximum semaphores system-wide
        semopm => 500,                   # Maximum semop ops per call
        semmni => 32000,                 # Maximum number of semaphore identifier sets
    }

Note: Linux has no per-process segment limit (C<shmseg>); only the system-wide
C<shmmni> applies. The four C<sem*> keys come from C</proc/sys/kernel/sem>
(one line: C<semmsl semmns semopm semmni>).

On FreeBSD, reads from C<sysctl kern.ipc>. Example return value:

    {
        shmmax => 536870912,  # Maximum size of a single segment (bytes)
        shmmin => 1,          # Minimum size of a single segment (bytes)
        shmmni => 192,        # Maximum number of segments system-wide
        shmseg => 128,        # Maximum number of segments per process
        shmall => 131072,     # Maximum total shared memory (pages)
        semmni => 50,         # Maximum number of semaphore identifier sets
        semmns => 340,        # Maximum semaphores system-wide
        semmsl => 340,        # Maximum semaphores per set
        semopm => 100,        # Maximum semop ops per call
    }

On OpenBSD, reads from C<sysctl kern.seminfo kern.shminfo>. Example return
value:

    {
        shmmax => 33554432,  # Maximum size of a single segment (bytes)
        shmmin => 1,         # Minimum size of a single segment (bytes)
        shmmni => 128,       # Maximum number of segments system-wide
        shmall => 8192,      # Maximum total shared memory (pages)
        semmni => 10,        # Maximum number of semaphore identifier sets
        semmns => 60,        # Maximum semaphores system-wide
        semmsl => 60,        # Maximum semaphores per set
    }

On Solaris (including OmniOS/illumos), the kernel's SysV configuration is
not yet read programmatically. This method returns C<undef> on Solaris; use
system tools such as C<prctl> or C<mdb -k> to inspect the kernel IPC limits
instead.

C<semmni> in particular is the limit that test suites making heavy use of
shared-memory tied variables most often hit. FreeBSD's default of 50 is
unusually tight; OpenBSD's default of 10 is tighter still. Test code that
needs to scale by available capacity can compute
C<< $info->{semmni} - IPC::Shareable::sem_count() >> as the headroom
currently available for new allocations.

Return: Hash reference, or C<undef> if the platform is not supported or no data
could be read.


=head1 METHODS - UNIT TESTING


=head2 testing_set($dist_name)

    IPC::Shareable->testing_set('My::Distribution');

Sets a process-level tag so that every subsequent C<tie()> in the same process
automatically receives C<< testing => 'My::Distribution' >> without needing it
on each individual tie.  The tag propagates to nested-segment children (created
automatically when a reference is stored into a tied variable) and to any
processes forked B<after> the call, because C<fork()> copies the parent's memory.

Call this once at the top of each test file (or from a shared helper module
loaded with C<use>).

This flag can also be set with the L</testing> flag in the initial tie params.

Parameters:

    $dist_name

Mandatory, non-empty string: conventionally the distribution name.

Croaks if C<$dist_name> is undefined or empty.

=head2 clean_up_testing($dist_name)

    IPC::Shareable::clean_up_testing('My::Distribution');

    # or as a method:

    IPC::Shareable->clean_up_testing('My::Distribution');

Performs a B<system-wide> scan for every IPC::Shareable segment whose
C<SEM_TESTING> semaphore slot contains the CRC32 hash of C<$dist_name>, and
removes each matching segment and its semaphore set -- B<except> one that
another, still-running process owns.

A matching segment is removed when it was created by the calling process, or
when its creator process has since exited (ie. an orphan left by a crashed run).
A segment whose creator is still alive in some other process is left untouched.
This makes the call safe to use even while the same distribution's test suite is
running concurrently -- under C<prove -j>, or by several smokers at once -- where
it would otherwise tear down segments those sibling processes are still using.

Unlike L</clean_up_all>, this function is not limited to segments in
C<%global_register>: it will find and remove orphaned segments from previous
crashed test runs.  Unlike L<clean_up_protected|/clean_up_protected($protect_key)>,
it deliberately ignores the C<protected> attribute -- a matching segment tagged
with C<testing> is removed regardless.

A second pass reclaims B<orphaned testing semaphore sets> -- ones whose shared
memory segment is already gone, eg. when a crashed run died between removing a
segment and removing its semaphore set. Such a set can never be re-attached
(the segment is always created before its semaphore set), yet it pins one of
the system's C<SEMMNI> slots forever; on hosts with a tiny limit (OpenBSD
defaults to C<kern.seminfo.semmni=10>) the accumulation eventually starves
every subsequent C<semget()> into C<ENOSPC>. Only sets carrying the matching
C<SEM_TESTING> marker are touched.

The typical usage is at the top of the first test file (before any segments are
created) to clear orphans, and optionally at the end of the last test file as a
belt-and-suspenders cleanup:

    # t/00-base.t

    # First, clean up from the previous run if necessary

    my $n = IPC::Shareable::clean_up_testing('My::Distribution');
    note "Removed $n orphaned segments from previous run" if $n;

    # Now set tagging for segments in this test file

    IPC::Shareable->testing_set('My::Distribution');

Parameters:

    $dist_name

Mandatory, non-empty string: the same string passed to L</testing_set($dist_name)>
or the C<testing> tie attribute.

Return: integer count of removed segments.

B<Note>: C<attributes('testing')> on a re-attached segment returns the stored
integer hash, not the original string.  This is intentional: the hash is
sufficient for cleanup comparisons and the original string is never stored on
the system.


=head1 LOCKING

IPC::Shareable provides methods to implement application-level advisory and
enforced locking of the shared data structures.  These methods are C<lock()> and
C<unlock()>. To use them you must first get the object underlying the tied
variable, either by saving the return value of the original call to C<tie()> or
by using the built-in C<tied()> function.

See L<lock()|/lock($flags, $code)> for flag combinations allowed.

=head2 Lock and unlock

To lock and subsequently unlock a variable, do this:

    tie my %hash, 'IPC::Shareable', { %options };

    tied(%hash)->lock;
    $hash{a}->{b} = 1;
    tied(%hash)->unlock;

This will place an exclusive lock on the data of C<%hash>, including all nested
data below the parent. You can also get shared locks or attempt to get a lock
without blocking.

L<IPC::Shareable> makes the constants C<LOCK_EX>, C<LOCK_SH>, C<LOCK_NB>, and
C<LOCK_UN> exportable to your address space with the export tags C<:lock>,
C<:flock>, or C<:all>. The values should be the same as the standard C<flock>
option arguments.

When attempting to get a blocking lock (eg. C<LOCK_EX> or C<LOCK_SH>) while
another process has an exclusive write lock (C<LOCK_EX>), your call will block
and wait until the other process releases its exclusive lock. The same thing
happens if you attempt to get a C<LOCK_EX> if there are any other processes that
hold a C<LOCK_SH>.

Here is an example of how to manage a non-blocking lock:

    if (tied(%hash)->lock(LOCK_SH|LOCK_NB)) {
        print "The value is $hash{a}\n";
        tied(%hash)->unlock;
    }
    else {
        print "Another process has an exclusive lock.\n";
    }

If no argument is provided to C<lock>, it defaults to C<LOCK_EX>.

=head2 Enforced write and read locking

Additional safeguards are in place to protect your locked data from processes
that don't bother to implement locking explicitly.

=head3 Violating an enforced write lock

By default, the C<enforced_write_locking> option is set to true, which means
that if a tied variable sets a C<LOCK_EX>, all writes from all other processes
will fail, and their data will not be updated.

If the offending process has C<violated_write_lock_warn> set to true (also
default), it will receive a warning regarding the issue.

=head3 Violating an enforced read lock

Also enabled by default, the C<enforced_read_locking> will catch instances where
a process attempts a read of data that is currently locked with C<LOCK_EX> by
another process. Unlike write protection, read protection does not prevent the
read; it simply sets the stage for you to be able to warn the user that they
are receiving stale data.

To have the user warned that they are in fault, the C<violated_read_lock_warn>
option must be set to true, which it is by default. The warning advises the user
that the data they have received is stale, and that they should refactor their
code to implement proper locking.

=head2 Important notes

Note that in the background, we perform lock optimization when reading and
writing to the shared storage even if the advisory locks aren't being used.

Using the advisory locks can speed up processes that are doing several writes/
reads at the same time (ie. transactions).

When using C<lock()> to lock a variable, be careful to guard against
signals.  Under normal circumstances, C<IPC::Shareable>'s C<END> method
unlocks any locked variables when the process exits.  However, if an
untrapped signal is received while a process holds a lock, C<END> will
not be called.

This is I<not> a deadlock risk: all semaphore lock operations in
C<IPC::Shareable> use the C<SEM_UNDO> flag, which causes the kernel to
automatically reverse any semaphore operations when the process exits,
regardless of the cause of death (including C<SIGKILL> and hardware
faults). Other processes waiting for the lock will be unblocked.

=head1 LOCKING BEHAVIOR MATRIX

The following matrix describes what happens to a second object (B) when a
first object (A) holds C<LOCK_EX> on a segment, across all combinations of
the four lock-control attributes:

=over 4

=item * EW = C<enforced_write_locking>

=item * ER = C<enforced_read_locking>

=item * WW = C<violated_write_lock_warn>

=item * WR = C<violated_read_lock_warn>

=back

=head2 Lock acquisition (attribute-independent)

C<semop> runs at the kernel level; none of the four flags affect whether a
lock is granted.

    +--------------------------+----------------------------------------------+
    | B's attempt              | Lock result while A holds LOCK_EX            |
    +--------------------------+----------------------------------------------+
    | LOCK_EX                  | Blocks, then acquires once A unlocks         |
    | LOCK_EX | LOCK_NB        | Returns 0 immediately                        |
    | LOCK_SH                  | Blocks, then acquires once A unlocks         |
    | LOCK_SH | LOCK_NB        | Returns 0 immediately                        |
    | (no lock)                | N/A                                          |
    +--------------------------+----------------------------------------------+

=head2 Behavior after lock state is established

=head3 Case 1: B successfully holds LOCK_EX (blocking attempts complete after A unlocks)

All flags are irrelevant; C<FETCH> uses the cache (skipping the read check),
and the write check bypasses on C<LOCK_EX> ownership.

    +----------+--------------+-----------+--------------+
    | Read     | Read warn?   | Write     | Write warn?  |
    +----------+--------------+-----------+--------------+
    | cache    | never        | succeeds  | never        |
    +----------+--------------+-----------+--------------+

=head3 Case 2: B successfully holds LOCK_SH (after A unlocks)

C<FETCH> uses cache (no read warn possible). Writes go through the write
check, which sees C<SEM_READERS E<gt> 0> from B's own C<LOCK_SH>.

    +----+----+------------------------------------+--------------+
    | EW | WW | Write outcome                      | Write warn?  |
    +----+----+------------------------------------+--------------+
    |  0 |  * | succeeds (enforcement off)         | no           |
    |  1 |  0 | blocked ("active readers")         | no           |
    |  1 |  1 | blocked ("active readers")         | YES          |
    +----+----+------------------------------------+--------------+

=head3 Case 3: B is unlocked (NB attempt returned 0, or B never attempted a lock); A still holds LOCK_EX, so SEM_WRITERS = 1

    +----+----+----+----+-------------------+--------------+-------------------+---------------+
    | EW | ER | WW | WR | Read              | Read warn?   | Write             | Write warn?   |
    +----+----+----+----+-------------------+--------------+-------------------+---------------+
    |  0 |  0 |  0 |  0 | raw shmem (stale) | no           | succeeds (race)   | no            |
    |  0 |  0 |  0 |  1 | raw shmem         | no           | succeeds          | no            |
    |  0 |  0 |  1 |  0 | raw shmem         | no           | succeeds          | no            |
    |  0 |  0 |  1 |  1 | raw shmem         | no           | succeeds          | no            |
    |  0 |  1 |  0 |  0 | raw shmem         | no           | succeeds          | no            |
    |  0 |  1 |  0 |  1 | raw shmem         | YES          | succeeds          | no            |
    |  0 |  1 |  1 |  0 | raw shmem         | no           | succeeds          | no            |
    |  0 |  1 |  1 |  1 | raw shmem         | YES          | succeeds          | no            |
    |  1 |  0 |  0 |  0 | raw shmem         | no           | blocked           | no            |
    |  1 |  0 |  0 |  1 | raw shmem         | no           | blocked           | no            |
    |  1 |  0 |  1 |  0 | raw shmem         | no           | blocked           | YES           |
    |  1 |  0 |  1 |  1 | raw shmem         | no           | blocked           | YES           |
    |  1 |  1 |  0 |  0 | raw shmem         | no           | blocked           | no            |
    |  1 |  1 |  0 |  1 | raw shmem         | YES          | blocked           | no            |
    |  1 |  1 |  1 |  0 | raw shmem         | no           | blocked           | YES           |
    |  1 |  1 |  1 |  1 | raw shmem         | YES          | blocked           | YES           |
    +----+----+----+----+-------------------+--------------+-------------------+---------------+

=head2 When A holds LOCK_SH instead of LOCK_EX

When A holds a shared lock, C<SEM_READERS E<gt> 0> and C<SEM_WRITERS = 0>.
This collapses the matrix in three significant ways:

=over 4

=item *

B<Lock acquisition diverges.> B's C<LOCK_SH> and C<LOCK_SH | LOCK_NB> both
succeed immediately; multiple readers can hold C<LOCK_SH> concurrently.
Only the C<LOCK_EX> attempts still block (or return 0 for the NB variant).

    +--------------------------+----------------------------------------------+
    | B's attempt              | Lock result while A holds LOCK_SH            |
    +--------------------------+----------------------------------------------+
    | LOCK_EX                  | Blocks, then acquires once A unlocks         |
    | LOCK_EX | LOCK_NB        | Returns 0 immediately                        |
    | LOCK_SH                  | Acquires immediately (concurrent readers OK) |
    | LOCK_SH | LOCK_NB        | Acquires immediately                         |
    | (no lock)                | N/A                                          |
    +--------------------------+----------------------------------------------+

=item *

B<Read warnings never fire.> The read check tests C<SEM_WRITERS E<gt> 0>,
which is false. ER and WR become irrelevant; unlocked reads return raw
shmem but never warn. The data is also genuinely fresher: A is reading, not
writing, so there is no stale-write risk.

=item *

B<Write warnings carry a different message.> Unlocked writes are still
blocked when C<EW = 1>, but via the C<SEM_READERS E<gt> 0> branch of the
write check. The warning text becomes:

    "...has active readers (enforced write locking enabled)"

rather than the "exclusively locked" variant. Write outcome and warn
behavior across (EW, WW) are otherwise identical to Case 3 above.

=back

=head2 Rules distilled from the matrix

=over 4

=item *

B<Lock acquisition> is governed only by SysV semaphores; the four flags do
not participate.

=item *

B<Read result> is always raw shmem when unlocked, always cached when locked;
the four flags only affect whether a warning is emitted, never the value
returned.

=item *

B<Read warns> if C<ER = 1> AND C<WR = 1> AND another process holds
C<LOCK_EX>.

=item *

B<Write blocks> if C<EW = 1> AND (another process holds C<LOCK_EX> OR has
active C<LOCK_SH> readers OR the caller itself holds only C<LOCK_SH>).

=item *

B<Write warns> iff the write was blocked AND C<WW = 1>.

=item *

C<LOCK_EX> ownership bypasses every check in the write path and never reaches
the read check, so the four flags never fire for the lock holder.

=back


=head1 DATA AND SEGMENT MAPPING

For simple data (none of the values are references), a single segment is used
throughout. However, with nested data, each value that is a reference is stored
in its own, separate shared memory segment (the key is auto-generated).

Consider a three-level hash:

    $h{a}{b}{c} = 1;

This creates three segments:

    Root segment  (SysV key 0xABCD)
      stored data: { a => <pointer to child key=11111> }
                              |
                              v
              Child segment  (SysV key 11111)
                stored data: { b => <pointer to grandchild key=22222> }
                                          |
                                          v
                        Grandchild segment  (SysV key 22222)
                          stored data: { c => 1 }

Each segment only knows about its direct children. The chain is followed
lazily, one level at a time, as you C<FETCH> down into the structure. (See the
L<shm_segments()|/shm_segments($key)> documentation to gather this structure within code).

When you replace a child with a new reference where the previous value was
also a reference, a new segment is created and the new data is stored there.
The old segment is automatically removed.

When a value that is a reference is deleted from the data, the memory segment
that held that data is automatically cleaned up and freed.

=head2 Storable

With the Storable serializer, nested references are handled transparently.
Storable natively freezes the entire Perl data structure (including internal
tie information for child segments) into a single binary blob. On thaw,
child segments are automatically re-attached without any explicit markers in
the serialized data.

This means that unlike JSON, there are no C<__ics__> placeholder objects in
the stored data. The trade-off is that Storable output is Perl-specific and
not portable across different Perl versions or platforms.

See the C<serializer> option under L</OPTIONS> to choose between C<json> and
C<storable>.

=head2 JSON

JSON can't serialize blessed objects, so each child pointer is written as an
explicit marker:

    { "__ics__" => { type => "HASH", child_key => 11111, child_key_hex => "0x00002b67" } }

The raw JSON in the root segment looks like:

    {"a":{"__ics__":{"type":"HASH","child_key":11111,"child_key_hex":"0x00002b67"}}}

The raw JSON in the child segment (key 11111) looks like:

    {"b":{"__ics__":{"type":"HASH","child_key":22222,"child_key_hex":"0x000056ce"}}}

Finally, the value in the child is not a reference, so it's stored as literal
data:

    {"c": 1}

On decode, any C<__ics__> marker is spotted and a tie with C<create =E<gt> 0> is
used to re-attach to the existing child segment by that key; no new segment is
created, it simply reconnects.

=head1 SEMAPHORES

Each memory segment that we utilize comes with it a semaphore set of four or
five individual semaphores. These semaphores keep state information about the
segment itself, and manages the locking aspects.  A fifth slot (C<SEM_TESTING>)
is added only when the segment is created with the L</testing> attribute.

=head2 SEM_MARKER

Semaphore slot ID 0. Signals whether the associated shared memory segment has
been initialized and is ready for use. C<1> if it is, C<0> if it isn't.

=head2 SEM_READERS

Semaphore slot ID 1. Specifies the current number of readers holding a
C<LOCK_SH>. A write lock (C<LOCK_EX>) can't be obtained until this value is
reduced to C<0>.

=head2 SEM_WRITERS

Semaphore slot ID 2. Value is C<1> if a process has a C<LOCK_EX> write lock,
and C<0> if not.

=head2 SEM_PROTECTED

Semaphore slot ID 3. Used to keep track of the C<protected> option value for
protected segments. See L</protected>.

=head2 SEM_TESTING

Semaphore slot ID 4. Present only on segments created with the L</testing>
attribute.  Stores the CRC32 hash of the distribution name (masked to a
positive 31-bit integer) so that L</clean_up_testing($dist_name)> can
identify and remove all matching segments system-wide.  Zero on segments
that were not created with C<testing>.

=head1 DESTRUCTION

perl will destroy the object underlying a tied variable when the tied variable
goes out of scope.  Unfortunately for L<IPC::Shareable>, this may not be
desirable: other processes may still need a handle on the relevant shared memory
segment.

L<IPC::Shareable> therefore provides several options to control the timing of
removal of shared memory segments.

B<Note>: The destruction is handled in an C<END> block. Only those memory
segments that are tied to the current process will be removed.

=head2 destroy Option

As described in L</OPTIONS>, specifying the B<destroy> option when
C<tie()>ing a variable coerces L<IPC::Shareable> to remove the underlying
shared memory segment when the process calling C<tie()> exits gracefully.

=head2 Signal handlers

The C<END> block only runs on a I<clean> exit (normal program
end, C<die>, or C<exit>). It does B<not> run for untrapped signals
(C<SIGTERM>, C<SIGINT>, etc.) or for C<SIGKILL>. If your process may be
terminated by a signal and you want C<destroy> cleanup to run, install
signal handlers that call C<exit>:

    $SIG{INT} = $SIG{TERM} = $SIG{HUP} = sub { exit };

This causes the C<END> block to fire on those signals. C<SIGKILL> cannot
be caught; any segments left behind by it can be recovered with
C<IPC::Shareable-E<gt>clean_up_all>.

=head2 Notes

B<Note>: If the segment was created with its L</protected> attribute set,
it will not be removed in the C<END> block, even if C<destroy> is set.

B<Note>: Advisory locks (C<lock()>/C<unlock()>) are I<always> released
automatically when a process dies, even on C<SIGKILL>, because the
underlying semaphore operations use C<SEM_UNDO>. Lock release is
therefore not a concern; only shared memory I<segment> data requires
the signal handler precaution above.

=head2 See also

See L</METHODS - MANUAL CLEANUP> for further information.


=head1 EXPORTS

We do not export anything by default. You must request an item individually, or
by tag.

=head2 Tags

=head3 :lock

Aliases: C<:flock>

Includes: C<LOCK_EX>, C<LOCK_SH>, C<LOCK_NB> and C<LOCK_UN>.

=head3 :flock

Simple legacy alias for C<:lock>.

=head3 :semaphores

Includes: C<SEM_MARKER>, C<SEM_READERS>, C<SEM_WRITERS>, C<SEM_PROTECTED> and
C<SEM_TESTING>.

=head3 :all

Includes L</:lock> and L</:semaphores>.


=head1 AUTHORS

    Benjamin Sugars <bsugars@canoe.ca>
    Steve Bertrand <steveb@cpan.org> (since 2016)


=head1 NOTES

=head2 Important Notes

=over 4

=item o

In v1.14, we changed our default serializer from C<Storable> to C<JSON>. For
backward compatibility, there is a process whereby if you have existing segments
saved in C<Storable> format and the JSON serializer can't process it, we'll
automatically fall back to C<Storable> for you. You should however recreate the
segments with the C<JSON> serializer.

=back

=head2 General Notes

=over 4

=item o

This distribution has minor parts of it developed in C/XS, but these components
are only built if we can determine that you've got the proper build tools
installed. If not, we simply skip the XS build and fall back to our pure Perl
code.

=item o

Iterating over a hash causes a special optimization if you have not
obtained a lock (it is better to obtain a read (or write) lock before
iterating over a hash tied to L<IPC::Shareable>, but we attempt this
optimization if you do not).

=item o

For tied hashes, the C<fetch>/C<thaw> operation is performed
when the first key is accessed.  Subsequent key and value
accesses are done without accessing shared memory.  Doing an
assignment to the hash or fetching another value between key
accesses causes the hash to be replaced from shared memory. The
state of the iterator in this case is not defined by the Perl
documentation. Caveat Emptor.

=back


=head1 CREDITS

Thanks to all those with comments or bug fixes, especially

    Maurice Aubrey      <maurice@hevanet.com>
    Stephane Bortzmeyer <bortzmeyer@pasteur.fr>
    Doug MacEachern     <dougm@telebusiness.co.nz>
    Robert Emmery       <roberte@netscape.com>
    Mohammed J. Kabir   <kabir@intevo.com>
    Terry Ewing         <terry@intevo.com>
    Tim Fries           <timf@dicecorp.com>
    Joe Thomas          <jthomas@women.com>
    Paul Makepeace      <Paul.Makepeace@realprogrammers.com>
    Raphael Manfredi    <Raphael_Manfredi@pobox.com>
    Lee Lindley         <Lee.Lindley@bigfoot.com>
    Dave Rolsky         <autarch@urth.org>
    Steve Bertrand      <steveb@cpan.org>


=head1 SEE ALSO

L<perltie>, L<Storable>, C<shmget>, C<ipcs>, C<ipcrm> and other SysV IPC manual
pages.

=cut
