package IPC::Shareable;

use warnings;
use strict;

require 5.00503;

use Carp qw(croak confess carp);
use IPC::Semaphore;
use IPC::Shareable::SharedMem;
use IPC::SysV qw(
    IPC_PRIVATE
    IPC_CREAT
    IPC_EXCL
    IPC_NOWAIT
    SEM_UNDO
);
use Storable 0.6 qw(freeze thaw);
use Scalar::Util;

our $VERSION = '1.04';

$SIG{CHLD} = 'IGNORE';

use constant {
    LOCK_SH     => 1,
    LOCK_EX     => 2,
    LOCK_NB     => 4,
    LOCK_UN     => 8,

    DEBUGGING   => ($ENV{SHAREABLE_DEBUG} or 0),
    SHM_BUFSIZ  =>  65536,
    SEM_MARKER  =>  0,
    SHM_EXISTS  =>  1,
};

require Exporter;
our @ISA = 'Exporter';
our @EXPORT_OK = qw(LOCK_EX LOCK_SH LOCK_NB LOCK_UN);
our %EXPORT_TAGS = (
    all     => [qw( LOCK_EX LOCK_SH LOCK_NB LOCK_UN )],
    lock    => [qw( LOCK_EX LOCK_SH LOCK_NB LOCK_UN )],
    flock   => [qw( LOCK_EX LOCK_SH LOCK_NB LOCK_UN )],
);
Exporter::export_ok_tags('all', 'lock', 'flock');

# Locking scheme copied from IPC::ShareLite -- ltl
my %semop_args = (
    (LOCK_EX),
    [
        1, 0, 0,                        # wait for readers to finish
        2, 0, 0,                        # wait for writers to finish
        2, 1, SEM_UNDO,                 # assert write lock
    ],
    (LOCK_EX|LOCK_NB),
    [
        1, 0, IPC_NOWAIT,               # wait for readers to finish
        2, 0, IPC_NOWAIT,               # wait for writers to finish
        2, 1, (SEM_UNDO | IPC_NOWAIT),  # assert write lock
    ],
    (LOCK_EX|LOCK_UN),
    [
        2, -1, (SEM_UNDO | IPC_NOWAIT),
    ],

    (LOCK_SH),
    [
        2, 0, 0,                        # wait for writers to finish
        1, 1, SEM_UNDO,                 # assert shared read lock
    ],
    (LOCK_SH|LOCK_NB),
    [
        2, 0, IPC_NOWAIT,               # wait for writers to finish
        1, 1, (SEM_UNDO | IPC_NOWAIT),  # assert shared read lock
    ],
    (LOCK_SH|LOCK_UN),
    [
        1, -1, (SEM_UNDO | IPC_NOWAIT), # remove shared read lock
    ],
);

my %default_options = (
    key       => IPC_PRIVATE,
    create    => 0,
    exclusive => 0,
    destroy   => 0,
    graceful  => 0,
    warn      => 0,
    mode      => 0666,
    size      => SHM_BUFSIZ,
);

my %global_register;
my %process_register;
my %used_ids;

sub _trace;
sub _debug;

# --- "Magic" methods
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

    my $sid = $knot->seg->{_id};

    $global_register{$sid} ||= $knot;

    $knot->{_data} = _thaw($knot->seg) unless ($knot->{_lock});

    if ($knot->{_type} eq 'HASH') {
        my $key = shift;
        my $val = shift;
        _mg_tie($knot, $val) if _need_tie($val);
        $knot->{_data}{$key} = $val;
    }
    elsif ($knot->{_type} eq 'ARRAY') {
        my $i   = shift;
        my $val = shift;
        _mg_tie($knot, $val) if _need_tie($val);
        $knot->{_data}->[$i] = $val;
    }
    elsif ($knot->{_type} eq 'SCALAR') {
        my $val = shift;
        _mg_tie($knot, $val) if _need_tie($val);
        $knot->{_data} = \$val;
    }
    else {
        croak "Variables of type $knot->{_type} not supported";
    }

    if ($knot->{_lock} & LOCK_EX) {
        $knot->{_was_changed} = 1;
    } else {
        if (! defined _freeze($knot->seg, $knot->{_data})){
            croak "Could not write to shared memory: $!\n";
        }
    }
    return 1;
}
sub FETCH {
    my $knot = shift;

    my $sid = $knot->seg->{_id};

    $global_register{$sid} ||= $knot;

    my $data;
    if ($knot->{_lock} || $knot->{_iterating}) {
        $knot->{_iterating} = 0; # In case we break out
        $data = $knot->{_data};
    } else {
        $data = _thaw($knot->seg);
        $knot->{_data} = $data;
    }

    my $val;

    if ($knot->{_type} eq 'HASH') {
        if (defined $data) {
            my $key = shift;
            $val = $data->{$key};
        } else {
            return;
        }
    }
    elsif ($knot->{_type} eq 'ARRAY') {
        if (defined $data) {
            my $i = shift;
            $val = $data->[$i];
        } else {
            return;
        }
    }
    elsif ($knot->{_type} eq 'SCALAR') {
        if (defined $data) {
            $val = $$data;
        } else {
            return;
        }
    }
    else {
        croak "Variables of type $knot->{_type} not supported";
    }

    if (my $inner = _is_kid($val)) {
        my $s = $inner->seg;
        $inner->{_data} = _thaw($s);
    }
    return $val;

}
sub CLEAR {
    my $knot = shift;

    if ($knot->{_type} eq 'HASH') {
        $knot->{_data} = { };
    }
    elsif ($knot->{_type} eq 'ARRAY') {
        $knot->{_data} = [ ];
    }

    else {
        croak "Attempt to clear non-aggegrate";
    }

    if ($knot->{_lock} & LOCK_EX) {
        $knot->{_was_changed} = 1;
    } else {
        if (! defined _freeze($knot->seg, $knot->{_data})){
            croak "Could not write to shared memory: $!";
        }
    }
}
sub DELETE {
    my $knot = shift;
    my $key  = shift;

    $knot->{_data} = _thaw($knot->seg) unless $knot->{_lock};
    my $val = delete $knot->{_data}->{$key};
    if ($knot->{_lock} & LOCK_EX) {
        $knot->{_was_changed} = 1;
    } else {
        if (! defined _freeze($knot->seg, $knot->{_data})){
            croak "Could not write to shared memory: $!";
        }
    }

    return $val;
}
sub EXISTS {
    my $knot = shift;
    my $key  = shift;

    $knot->{_data} = _thaw($knot->seg) unless $knot->{_lock};
    return exists $knot->{_data}->{$key};
}
sub FIRSTKEY {
    my $knot = shift;

    $knot->{_iterating} = 1;
    $knot->{_data} = _thaw($knot->seg) unless $knot->{_lock};
    my $reset = keys %{$knot->{_data}};
    my $first = each %{$knot->{_data}};
    return $first;
}
sub NEXTKEY {
    my $knot = shift;

    # caveat emptor if hash was changed by another process
    my $next = each %{$knot->{_data}};
    if (not defined $next) {
        $knot->{_iterating} = 0;
        return;
    } else {
        $knot->{_iterating} = 1;
        return $next;
    }
}
sub EXTEND {
    #XXX Noop
}
sub PUSH {
    my $knot = shift;

    $global_register{$knot->seg->id} ||= $knot;
    $knot->{_data} = _thaw($knot->seg, $knot->{_data}) unless $knot->{_lock};

    push @{$knot->{_data}}, @_;
    if ($knot->{_lock} & LOCK_EX) {
        $knot->{_was_changed} = 1;
    } else {
        if (! defined _freeze($knot->seg, $knot->{_data})){
            croak "Could not write to shared memory: $!";
        };
    }
}
sub POP {
    my $knot = shift;

    $knot->{_data} = _thaw($knot->seg, $knot->{_data}) unless $knot->{_lock};

    my $val = pop @{$knot->{_data}};
    if ($knot->{_lock} & LOCK_EX) {
        $knot->{_was_changed} = 1;
    } else {
        if (! defined _freeze($knot->seg, $knot->{_data})){
            croak "Could not write to shared memory: $!";
        }
    }
    return $val;
}
sub SHIFT {
    my $knot = shift;

    $knot->{_data} = _thaw($knot->seg, $knot->{_data}) unless $knot->{_lock};
    my $val = shift @{$knot->{_data}};
    if ($knot->{_lock} & LOCK_EX) {
        $knot->{_was_changed} = 1;
    } else {
        if (! defined _freeze($knot->seg, $knot->{_data})){
            croak "Could not write to shared memory: $!";
        }
    }
    return $val;
}
sub UNSHIFT {
    my $knot = shift;

    $knot->{_data} = _thaw($knot->seg, $knot->{_data}) unless $knot->{_lock};
    my $val = unshift @{$knot->{_data}}, @_;
    if ($knot->{_lock} & LOCK_EX) {
        $knot->{_was_changed} = 1;
    } else {
        if (! defined _freeze($knot->seg, $knot->{_data})){
            croak "Could not write to shared memory: $!";
        }
    }
    return $val;
}
sub SPLICE {
    my($knot, $off, $n, @av) = @_;

    $knot->{_data} = _thaw($knot->seg, $knot->{_data}) unless $knot->{_lock};
    my @val = splice @{$knot->{_data}}, $off, $n, @av;
    if ($knot->{_lock} & LOCK_EX) {
        $knot->{_was_changed} = 1;
    } else {
        if (! defined _freeze($knot->seg, $knot->{_data})){
            croak "Could not write to shared memory: $!";
        }
    }
    return @val;
}
sub FETCHSIZE {
    my $knot = shift;

    $knot->{_data} = _thaw($knot->seg) unless $knot->{_lock};
    return scalar(@{$knot->{_data}});
}
sub STORESIZE {
    my $knot = shift;
    my $n    = shift;

    $knot->{_data} = _thaw($knot->seg) unless $knot->{_lock};
    $#{$knot->{_data}} = $n - 1;
    if ($knot->{_lock} & LOCK_EX) {
        $knot->{_was_changed} = 1;
    } else {
        if (! defined _freeze($knot->seg, $knot->{_data})){
            croak "Could not write to shared memory: $!";
        }
    }
    return $n;
}

# --- Public methods

sub global_register {
    return \%global_register;
}
sub process_register {
    return \%process_register;
}

sub spawn {
    my ($knot, %opts) = @_;

    croak "spawn() requires a key/glue sent in..." if ! defined $opts{key};

    $opts{mode} = 0666 if ! defined $opts{mode};

    _spawn(
        key     => $opts{key},
        mode    => $opts{mode},
    );
}
sub _spawn {
    my (%opts) = @_;

    my $pid = fork;
    return if $pid;

    if (! $pid) {
        tie my %h, 'IPC::Shareable', {
            key       => $opts{key},
            create    => 1,
            #exclusive => 1,
            destroy   => $opts{destroy},
            mode      => $opts{mode},
        };

        $h{__ipc}->{run} = 1;

        while (1) {
            local $SIG{__WARN__} = sub {};
            last if ! defined $h{__ipc};
            last if ! $h{__ipc}->{run};
        }

        IPC::Shareable->clean_up_all if $opts{destroy};
        exit 0;
    }
}
sub unspawn {
    shift;
    my ($key, $destroy) = @_;

    $destroy ||= 0;

    tie my %h, 'IPC::Shareable', {
        key       => $key,
        destroy   => $destroy,
        mode      => 0666,
    };

    $h{__ipc}->{run} = 0;

    sleep 1;

    IPC::Shareable->clean_up_all if $destroy;
}
sub lock {
    my ($knot, $flags) = @_;
    $flags = LOCK_EX if ! defined $flags;

    return $knot->unlock if ($flags & LOCK_UN);

    return 1 if ($knot->{_lock} & $flags);

    # If they have a different lock than they want, release it first
    $knot->unlock if ($knot->{_lock});

    my $sem = $knot->sem;
    my $return_val = $sem->op(@{ $semop_args{$flags} });
    if ($return_val) {
        $knot->{_lock} = $flags;
        $knot->{_data} = _thaw($knot->seg),
    }
    return $return_val;
}
sub unlock {
    my $knot = shift;

    return 1 unless $knot->{_lock};
    if ($knot->{_was_changed}) {
        if (! defined _freeze($knot->seg, $knot->{_data})){
            croak "Could not write to shared memory: $!\n";
        }
        $knot->{_was_changed} = 0;
    }
    my $sem = $knot->sem;
    my $flags = $knot->{_lock} | LOCK_UN;
    $flags ^= LOCK_NB if ($flags & LOCK_NB);
    $sem->op(@{ $semop_args{$flags} });

    $knot->{_lock} = 0;

    1;
}
*shlock = \&lock;
*shunlock = \&unlock;

sub clean_up {
    my $class = shift;

    for my $s (values %process_register) {
        next unless $s->{attributes}{owner} == $$;
        remove($s);
    }
}
sub clean_up_all {
    my $class = shift;
    for my $s (values %process_register) {
        remove($s);
    }

    for my $s (values %global_register) {
        remove($s);
    }
}
sub remove {
    my $knot = shift;

    my $s = $knot->seg;
    my $id = $s->id;

    $s->remove or warn "Couldn't remove shared memory segment $id: $!";

    $s = $knot->sem;

    $s->remove or warn "Couldn't remove semaphore set $id: $!";

    delete $process_register{$id};
    delete $global_register{$id};
}
sub seg {
    my ($knot) = @_;
    return $knot->{_shm} if defined $knot->{_shm};
}
sub sem {
    my ($knot) = @_;
    return $knot->{_sem} if defined $knot->{_sem};
}
sub singleton {
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

END {
    for my $s (values %process_register) {
        unlock($s);
        next unless $s->{attributes}->{destroy};
        next unless $s->{attributes}->{owner} == $$;
        remove($s);
    }
}

# --- Private methods below
sub _freeze {
    my $seg  = shift;
    my $water = shift;

    my $ice = freeze $water;
    # Could be a large string.  No need to copy it.  substr more efficient
    substr $ice, 0, 0, 'IPC::Shareable';

    if (length($ice) > $seg->size) {
        croak "Length of shared data exceeds shared segment size";
    }
    $seg->shmwrite($ice);
}
sub _thaw {
    my $seg = shift;

    my $ice = $seg->shmread;

    return if ! $ice;

    my $tag = substr $ice, 0, 14, '';

    if ($tag eq 'IPC::Shareable') {
        my $water = thaw $ice;
        if (! defined($water)){
            croak "Munged shared memory segment (size exceeded?)";
        }
        return $water;
    } else {
        return;
    }
}
sub _tie {
    my $type  = shift;
    my $class = shift;
    my $opts  = _parse_args(@_);

    my $key      = _shm_key($opts);
    my $flags    = _shm_flags($opts);
    my $shm_size = $opts->{size};

    my $seg;

    if ($opts->{graceful}) {
        my $exclusive = eval {
            $seg = IPC::Shareable::SharedMem->new($key, $shm_size, $flags);
            1;
        };

        if (! defined $exclusive) {
            if ($opts->{warn}) {
                warn "Process ID $$ exited due to exclusive shared memory collision\n";
            }
            exit(0);
        }
    }
    else {
        $seg = IPC::Shareable::SharedMem->new($key, $shm_size, $flags);
    }

    if (! defined $seg) {
        if (! $opts->{create}) {
            confess "ERROR: Could not acquire shared memory segment... 'create' ".
                  "option is not set, and the segment hasn't been created " .
                  "yet:\n\n $!";
        }
        elsif ($opts->{create} && $opts->{exclusive}){
            croak "ERROR: Could not create shared memory segment. 'create' " .
                  "and 'exclusive' are set. Does the segment already exist? " .
                  "\n\n$!";
        }
        else {
            croak "ERROR: Could not create shared memory segment.\n\n$!n";
        }
    }

    my $sem = IPC::Semaphore->new($key, 3, $flags);
    if (! defined $sem){
        croak "Could not create semaphore set: $!\n";
    }

    if (! $sem->op(@{ $semop_args{(LOCK_SH)} }) ) {
        croak "Could not obtain semaphore set lock: $!\n";
    }

    my $knot = {
        attributes   => $opts,
        _iterating   => 0,
        _key         => $key,
        _lock        => 0,
        _shm         => $seg,
        _sem         => $sem,
        _type        => $type,
        _was_changed => 0,
    };

    $knot->{_data} = _thaw($seg);

    if ($sem->getval(SEM_MARKER) != SHM_EXISTS) {
        $global_register{$knot->{_shm}->id} ||= $knot;
        $process_register{$knot->{_shm}->id} ||= $knot;
        if (! $sem->setval(SEM_MARKER, SHM_EXISTS)){
            croak "Couldn't set semaphore during object creation: $!";
        }
    }

    $sem->op(@{ $semop_args{(LOCK_SH|LOCK_UN)} });

    return bless $knot, $class;
}
sub _parse_args {
    my($proto, $opts) = @_;

    $proto = defined $proto ? $proto :  0;
    $opts  = defined $opts  ? $opts  : { %default_options };

    if (ref $proto eq 'HASH') {
        $opts = $proto;
    }
    else {
        $opts->{key} = $proto;
    }
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
    $opts->{owner} = ($opts->{owner} or $$);
    $opts->{magic} = ($opts->{magic} or 0);
    return $opts;
}
sub _shm_key {
    my $hv = shift;
    my $val = ($hv->{key} or '');

    if ($val eq '') {
        return IPC_PRIVATE;
    }
    elsif ($val =~ /^\d+$/) {
        return $val;
    }
    else {
        # XXX This only uses the first four characters
        $val = pack   'A4', $val;
        $val = unpack 'i', $val;
        return $val;
    }
}
sub _shm_flags {
    # --- Parses the anonymous hash passed to constructors; returns a list
    # --- of args suitable for passing to shmget
    my $hv = shift;
    my $flags = 0;

    $flags |= IPC_CREAT if $hv->{create};
    $flags |= IPC_EXCL  if $hv->{exclusive};
    $flags |= ($hv->{mode} or 0666);

    return $flags;
}
sub _mg_tie {
    my $parent = shift;
    my $val = shift;

    # XXX How to generate a unique id ?
    my $key;
    if ($parent->{_key} == IPC_PRIVATE) {
        $key = IPC_PRIVATE;
    } else {
        do {
            $key = int(rand(1_000_000));
        } while ($used_ids{$key});
        $used_ids{$key}++;
    }
    my %opts = (
        %{$parent->{attributes}},
        key       => $key,
        exclusive => 1,
        create    => 1,
        magic     => 1,
    );

    # XXX I wish I didn't have to take a copy of data here and copy it back in
    # XXX Also, have to peek inside potential objects to see their implementation
    my $child;
    my $type = Scalar::Util::reftype( $val ) || '';

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
sub _is_kid {
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
sub _need_tie {
    my $val = shift;

    my $type = Scalar::Util::reftype( $val );
    return unless $type;

    if ($type eq "HASH") {
        return !(tied %$val);
    }
    elsif ($type eq "ARRAY") {
        return !(tied @$val);
    }
    elsif ($type eq "SCALAR") {
        return !(tied $$val);
    }

    return;
}

sub _trace {
    require Carp;
    require Data::Dumper;
    my $caller = '    ' . (caller(1))[3] . " called with:\n";
    my $i = -1;
    my @msg = map {
        ++$i;
        my $obj;
        if (ref eq 'IPC::Shareable') {
            '        ' . "\$_[$i] = $_: shmid: $_->{_shm}->{_id}; " .
                Data::Dumper->Dump([ $_->{attributes} ], [ 'opts' ]);
        } else {
            '        ' . Data::Dumper->Dump( [ $_ ] => [ "\_[$i]" ]);
        }
    }  @_;
    Carp::carp "IPC::Shareable ($$) debug:\n", $caller, @msg;
}
sub _debug {
    require Carp;
    require Data::Dumper;
    local $Data::Dumper::Terse = 1;
    my $caller = '    ' . (caller(1))[3] . " tells us that:\n";
    my @msg = map {
        my $obj;
        if (ref eq 'IPC::Shareable') {
            '        ' . "$_: shmid: $_->{_shm}->{_id}; " .
                Data::Dumper->Dump([ $_->{attributes} ], [ 'opts' ]);
        }
        else {
            '        ' . Data::Dumper::Dumper($_);
        }
    }  @_;
    Carp::carp "IPC::Shareable ($$) debug:\n", $caller, @msg;
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

    tie SCALAR, 'IPC::Shareable', OPTIONS;
    tie ARRAY,  'IPC::Shareable', OPTIONS;
    tie HASH,   'IPC::Shareable', OPTIONS;

    (tied VARIABLE)->lock;
    (tied VARIABLE)->unlock;

    (tied VARIABLE)->lock(LOCK_SH|LOCK_NB)
        or print "Resource unavailable\n";

    my $segment   = (tied VARIABLE)->seg;
    my $semaphore = (tied VARIABLE)->sem;

    (tied VARIABLE)->remove;

    IPC::Shareable->clean_up;
    IPC::Shareable->clean_up_all;

    # Ensure only one instance of a script can be run at any time

    IPC::Shareable->singleton('GLUE');

=head1 DESCRIPTION

IPC::Shareable allows you to tie a variable to shared memory making it
easy to share the contents of that variable with other Perl processes and
scripts.

Scalars, arrays, and hashes and even objects can be tied. The variable being
tied may contain arbitrarily complex data structures - including references to
arrays, hashes of hashes, etc.

The association between variables in distinct processes is provided by
GLUE (aka "key").  This is an integer number or 4 character string[1] that
serves as a common identifier for data across process space.  Hence the
statement

    tie my $scalar, 'IPC::Shareable', { key => 'GLUE', create => 1 };

...in program one and the statement

    tie my $variable, 'IPC::Shareable', { key => 'GLUE' };

...in program two will create and bind C<$scalar> the shared memory in program
one and bind it to C<$variable> in program two.

There is no pre-set limit to the number of processes that can bind to
data; nor is there a pre-set limit to the complexity of the underlying
data of the tied variables[2].  The amount of data that can be shared
within a single bound variable is limited by the system's maximum size
for a shared memory segment (the exact value is system-dependent).

The bound data structures are all linearized (using Raphael Manfredi's
L<Storable> module) before being slurped into shared memory.  Upon
retrieval, the original format of the data structure is recovered.
Semaphore flags can be used for locking data between competing processes.

=head1 OPTIONS

Options are specified by passing a reference to a hash as the fourth
argument to the C<tie()> function that enchants a variable.

The following fields are recognized in the options hash:

=head2 key

B<key> is the GLUE that is a direct reference to the shared memory segment
that's to be tied to the variable.

If this option is missing, we'll default to using C<IPC_PRIVATE>. This
default key will not allow sharing of the variable between processes.

Default: B<IPC_PRIVATE>

=head2 create

B<create> is used to control whether calls to C<tie()> create new shared
memory segments or not.  If B<create> is set to a true value,
L<IPC::Shareable> will create a new binding associated with GLUE as
needed.  If B<create> is false, C<IPC::Shareable> will not attempt to
create a new shared memory segment associated with GLUE.  In this
case, a shared memory segment associated with GLUE must already exist
or we'll C<croak()>.

Defult: B<false>

=head2 exclusive

If B<exclusive> field is set to a true value, we will C<croak()> if the data
binding associated with GLUE already exists.  If set to a false value, calls to
C<tie()> will succeed even if a shared memory segment associated with GLUE
already exists.

See L</graceful> for a silent, non-exception exit if a second process
attempts to obtain an in-use C<exclusive> segment.

Default: B<false>

=head2 graceful

If B<exclusive> is set to a true value, we normally C<die()> if a second
process attempts to obtain the same shared memory segment. Set B<graceful>
to true and we'll C<exit> silently and gracefully. This option does nothing
if C<exclusive> isn't set.

Useful for ensuring only a single process is running at a time.

Default: B<false>

=head2 mode

The B<mode> argument is an octal number specifying the access
permissions when a new data binding is being created.  These access
permission are the same as file access permissions in that C<0666> is
world readable, C<0600> is readable only by the effective UID of the
process creating the shared variable, etc.

Default: B<0666> (world read and writeable)

=head2 destroy

If set to a true value, the shared memory segment underlying the data
binding will be removed when the process calling C<tie()> exits (gracefully)[3].

Only those memory segments that were created by the current process will be
removed.

Use this option with care. In particular you should not use this option in a
program that will fork after binding the data.  On the other hand, shared memory
is a finite resource and should be released if it is not needed.

Default: B<false>

=head2 size

This field may be used to specify the size of the shared memory segment
allocated.

Default: C<IPC::Shareable::SHM_BUFSIZ()> (ie. B<65536>)

=head2 Default Option Values

Default values for options are:

     key       => IPC_PRIVATE,
     create    => 0,
     exclusive => 0,
     graceful  => 0,
     warn      => 0,
     destroy   => 0,
     mode      => 0,
     size      => IPC::Shareable::SHM_BUFSIZ(),

=head1 METHODS

=head2 singleton($glue, $warn)

Class method that ensures that only a single instance of a script can be run
at any given time.

Parameters:

    $glue

Mandatory, String: The key/glue that identifies the shared memory segment.

    $warn

Bool, Optional: Send in a true value to have subsequent processes throw a
warning that there's been a shared memory violation and that it will exit.

Default: B<false>

=head2 spawn(%opts)

Spawns a forked process running in the background that holds the shared memory
segments backing your variable open.

Parameters:

Paremters are sent in as a hash.

    key => $glue

Mandatory, String/Integer: The glue that you will be accessing your data as.

    mode => 0666

Optional, Integer: The read/write permissions on the variable. Defaults to
C<0666>.

Example:

    use IPC::Shareable;

    # following line sets things up and returns

    IPC::Shareable->spawn(key => 'GLUE');

Now, either within the same script, or any other script on the system, your
data will be available at the key/glue C<GLUE>. Call
L<unspawn()|/unspawn($key, $destroy)> to remove it.

=head2 unspawn($key, $destroy)

This method will kill off the background process created with
L<spawn()|/spawn(%opts)>.

Parameters:

    $key

Mandatory, String/Integer: The glue (aka key) used in the call to C<spawn()>.

    $destroy

Optional, Bool. If set to a true value, we will remove all semaphores and memory
segments related to your data, thus removing the data in its entirety. If not
set to a true value, we'll leave the memory segments in place, and you'll be
able to re-attach to the data at any time. Defaults to false (C<0>).

=head2 lock($flags)

Obtains a lock on the shared memory. C<$flags> specifies the type
of lock to acquire.  If C<$flags> is not specified, an exclusive
read/write lock is obtained.  Acceptable values for C<$flags> are
the same as for the C<flock()> system call.

Returns C<true> on success, and C<undef> on error.  For non-blocking calls
(see below), the method returns C<0> if it would have blocked.

Obtain an exclusive lock like this:

        tied(%var)->lock(LOCK_EX); # same as default

Only one process can hold an exclusive lock on the shared memory at
a given time.

Obtain a shared (read) lock:

        tied(%var)->lock(LOCK_SH);

Multiple processes can hold a shared (read) lock at a given time.  If a process
attempts to obtain an exclusive lock while one or more processes hold
shared locks, it will be blocked until they have all finished.

Either of the locks may be specified as non-blocking:

        tied(%var)->lock( LOCK_EX|LOCK_NB );
        tied(%var)->lock( LOCK_SH|LOCK_NB );

A non-blocking lock request will return C<0> if it would have had to
wait to obtain the lock.

Note that these locks are advisory (just like flock), meaning that
all cooperating processes must coordinate their accesses to shared memory
using these calls in order for locking to work.  See the C<flock()> call for
details.

Locks are inherited through forks, which means that two processes actually
can possess an exclusive lock at the same time.  Don't do that.

The constants C<LOCK_EX>, C<LOCK_SH>, C<LOCK_NB>, and C<LOCK_UN> are available
for import using any of the following export tags:

        use IPC::Shareable qw(:lock);
        use IPC::Shareable qw(:flock);
        use IPC::Shareable qw(:all);

Or, just use the flock constants available in the Fcntl module.

See L</LOCKING> for further details.

=head2 unlock

Removes a lock. Takes no parameters, returns C<true> on success.

This is equivalent of calling C<shlock(LOCK_UN)>.

See L</LOCKING> for further details.

=head2 seg

Called on either the tied variable or the tie object, returns the shared
memory segment object currently in use.

=head2 sem

Called on either the tied variable or the tie object, returns the semaphore
object related to the memory segment currently in use.

=head2 global_register

Returns a hash reference of hashes of all in-use shared memory segments across
all processes. The key is the memory segment ID, and the value is the segment
and semaphore objects.

=head2 process_register

Returns a hash reference of hashes of all in-use shared memory segments created
by the calling process. The key is the memory segment ID, and the value is the
segment and semaphore objects.

=head1 LOCKING

IPC::Shareable provides methods to implement application-level
advisory locking of the shared data structures.  These methods are
called C<shlock()> and C<shunlock()>.  To use them you must first get the
object underlying the tied variable, either by saving the return
value of the original call to C<tie()> or by using the built-in C<tied()>
function.

To lock and subsequently unlock a variable, do this:

    my $knot = tie my %hash, 'IPC::Shareable', { %options };

    $knot->lock;
    $hash{a} = 'foo';
    $knot->unlock;

or equivalently, if you've decided to throw away the return of C<tie()>:

    tie my %hash, 'IPC::Shareable', { %options };

    tied(%hash)->lock;
    $hash{a} = 'foo';
    tied(%hash)->unlock;

This will place an exclusive lock on the data of C<$scalar>.  You can
also get shared locks or attempt to get a lock without blocking.

L<IPC::Shareable> makes the constants C<LOCK_EX>, C<LOCK_SH>, C<LOCK_UN>, and
C<LOCK_NB> exportable to your address space with the export tags
C<:lock>, C<:flock>, or C<:all>.  The values should be the same as
the standard C<flock> option arguments.

    if (tied(%hash)->lock(LOCK_SH|LOCK_NB)){
        print "The value is $hash{a}\n";
        tied(%hash)->unlock;
    } else {
        print "Another process has an exlusive lock.\n";
    }

If no argument is provided to C<lock>, it defaults to C<LOCK_EX>.

There are some pitfalls regarding locking and signals about which you
should make yourself aware; these are discussed in L</NOTES>.

Note that in the background, we perform lock optimization when reading and
writing to the shared storage even if the advisory locks aren't being used.

Using the advisory locks can speed up processes that are doing several writes/
reads at the same time.

=head1 REFERENCES

Although references can reside within a shared data structure, the tied variable
can not be a reference itself.

=head1 DESTRUCTION

perl(1) will destroy the object underlying a tied variable when then
tied variable goes out of scope.  Unfortunately for L<IPC::Shareable>,
this may not be desirable: other processes may still need a handle on
the relevant shared memory segment.

L<IPC::Shareable> therefore provides several options to control the timing of
removal of shared memory segments.

=head2 destroy Option

As described in L</OPTIONS>, specifying the B<destroy> option when
C<tie()>ing a variable coerces L<IPC::Shareable> to remove the underlying
shared memory segment when the process calling C<tie()> exits gracefully.

B<NOTE>: The destruction is handled in an C<END> block. Only those memory
segments that are tied to the current process will be removed.

=head2 remove

    tied($var)->remove;

    # or

    $knot->remove;

Calling C<remove()> on the object underlying a C<tie()>d variable removes
the associated shared memory segments.  The segment is removed
irrespective of whether it has the B<destroy> option set or not and
irrespective of whether the calling process created the segment.

=head2 clean_up

    IPC::Shareable->clean_up;

    # or

    tied($var)->clean_up;

    # or

    $knot->clean_up;

This is a class method that provokes L<IPC::Shareable> to remove all
shared memory segments created by the process.  Segments not created
by the calling process are not removed.

=head2 clean_up_all

    IPC::Shareable->clean_up_all;

    # or

    tied($var)->clean_up_all;

    # or

    $knot->clean_up_all

This is a class method that provokes L<IPC::Shareable> to remove all
shared memory segments encountered by the process.  Segments are
removed even if they were not created by the calling process.

=head1 RETURN VALUES

Calls to C<tie()> that try to implement L<IPC::Shareable> will return an
instance of C<IPC::Shareable> on success, and C<undef> otherwise.

=head1 AUTHOR

Benjamin Sugars <bsugars@canoe.ca>

=head1 NOTES

=head2 Footnotes from the above sections

=over 4

=item 1

If GLUE is longer than 4 characters, only the 4 most significant
characters are used.  These characters are turned into integers by
unpack()ing them.  If GLUE is less than 4 characters, it is space
padded.

=item 2

IPC::Shareable provides no pre-set limits, but the system does.
Namely, there are limits on the number of shared memory segments that
can be allocated and the total amount of memory usable by shared
memory.

=item 3

If the process has been smoked by an untrapped signal, the binding
will remain in shared memory.  If you're cautious, you might try

 $SIG{INT} = \&catch_int;
 sub catch_int {
     die;
 }
 ...
 tie $variable, IPC::Shareable, { key => 'GLUE', create => 1, 'destroy' => 1 };

which will at least clean up after your user hits CTRL-C because
IPC::Shareable's END method will be called.  Or, maybe you'd like to
leave the binding in shared memory, so subsequent process can recover
the data...

=back

=head2 General Notes

=over 4

=item o

When using C<lock()> to lock a variable, be careful to guard against
signals.  Under normal circumstances, C<IPC::Shareable>'s C<END> method
unlocks any locked variables when the process exits.  However, if an
untrapped signal is received while a process holds an exclusive lock,
C<DESTROY> will not be called and the lock may be maintained even though
the process has exited.  If this scares you, you might be better off
implementing your own locking methods.

One advantage of using C<flock> on some known file instead of the
locking implemented with semaphores in C<IPC::Shareable> is that when a
process dies, it automatically releases any locks.  This only happens
with C<IPC::Shareable> if the process dies gracefully.

The alternative
is to attempt to account for every possible calamitous ending for your
process (robust signal handling in Perl is a source of much debate,
though it usually works just fine) or to become familiar with your
system's tools for removing shared memory and semaphores.  This
concern should be balanced against the significant performance
improvements you can gain for larger data structures by using the
locking mechanism implemented in IPC::Shareable.

=item o

There is a program called C<ipcs>(1/8) (and C<ipcrm>(1/8)) that is
available on at least Solaris and Linux that might be useful for
cleaning moribund shared memory segments or semaphore sets produced
by bugs in either IPC::Shareable or applications using it.

Examples:

    # List all semaphores and memory segments in use on the system

    ipcs -a

    # List all memory segments along with each one's associated process ID

    ipcs -ap

    # Remove *all* semaphores and memory segments

    ipcrm -a

=item o

This version of L<IPC::Shareable> does not understand the format of
shared memory segments created by versions prior to C<0.60>.  If you try
to tie to such segments, you will get an error.  The only work around
is to clear the shared memory segments and start with a fresh set.

=item o

Iterating over a hash causes a special optimization if you have not
obtained a lock (it is better to obtain a read (or write) lock before
iterating over a hash tied to L<IPC::Shareable>, but we attempt this
optimization if you do not).

The C<fetch>/C<thaw> operation is performed
when the first key is accessed.  Subsequent key and and value
accesses are done without accessing shared memory.  Doing an
assignment to the hash or fetching another value between key
accesses causes the hash to be replaced from shared memory.  The
state of the iterator in this case is not defined by the Perl
documentation.  Caveat Emptor.

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


