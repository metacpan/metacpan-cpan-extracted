package File::KeePass::KDBX;
# ABSTRACT: Read and write KDBX files (using the File::KDBX backend)

use utf8;
use warnings;
use strict;

use Crypt::PRNG qw(irand);
use Crypt::Misc 0.029 qw(decode_b64 encode_b64);
use File::KDBX 0.900;
use File::KDBX::Constants qw(:header :magic :version);
use File::KDBX::Loader::KDB;
use File::KDBX::Util qw(clone_nomagic generate_uuid load_optional);
use Hash::Util::FieldHash qw(fieldhashes);
use Module::Load;
use Scalar::Util qw(blessed looks_like_number weaken);
use boolean;
use namespace::clean;

our $VERSION = '0.902'; # VERSION

fieldhashes \my (%KDBX, %TIED);

BEGIN {
    our @ISA;
    @ISA = qw(File::KeePass) if $INC{'File/KeePass.pm'};
}


sub new {
    my $class = shift;

    # copy constructor
    return $_[0]->clone if @_ == 1 && (blessed $_[0] // '') eq __PACKAGE__;

    if (@_ == 1 && blessed $_[0] && $_[0]->isa('File::KeePass')) {
        return $class->from_fkp(@_);
    }

    if (@_ == 1 && blessed $_[0] && $_[0]->isa('File::KDBX')) {
        my $self = bless {}, $class;
        $self->kdbx($_[0]);
        return $self;
    }

    my $args = ref $_[0] ? {%{$_[0]}} : {@_};
    my $self = bless $args, $class;
    exists $args->{kdbx} and $self->kdbx(delete $args->{kdbx});
    return $self;
}

sub DESTROY { $_[0]->clear }


sub clone {
    my $self = shift;
    require Storable;
    return Storable::dclone($self);
}

sub STORABLE_freeze {
    my $self = shift;
    my $copy = {%$self};
    delete @$self{qw(header groups)};
    return '', $copy, $KDBX{$self};
}

sub STORABLE_thaw {
    my $self    = shift;
    my $cloning = shift;
    shift;  # empty
    my $copy    = shift;
    my $kdbx    = shift;

    @$self{keys %$copy} = values %$copy;
    $self->kdbx($kdbx) if $kdbx;
}


sub clear {
    my $self = shift;
    delete $KDBX{$self};
    delete $TIED{$self};
    delete @$self{qw(header groups)};
}


sub kdbx {
    my $self = shift;
    $self = $self->new if !ref $self;
    if (@_) {
        $self->clear;
        $KDBX{$self} = shift;
    }
    $KDBX{$self} //= File::KDBX->new;
}


sub to_fkp {
    my $self = shift;
    load_optional('File::KeePass');
    return File::KeePass->new(clone_nomagic({%$self, header => $self->header, groups => $self->groups}));
}


sub from_fkp {
    my $class = shift;
    my $k = shift;
    my $kdbx = File::KDBX::Loader::KDB::convert_keepass_to_kdbx($k);
    my $self = bless {}, $class;
    $self->kdbx($kdbx);
    return $self;
}


sub load_db {
    my $self = shift;
    my $file = shift or die "Missing file\n";
    my $pass = shift or die "Missing pass\n";
    my $args = shift || {};

    open(my $fh, '<:raw', $file) or die "Could not open $file: $!\n";
    $self->_load($fh, $pass, $args);
}


sub parse_db {
    my ($self, $buf, $pass, $args) = @_;

    my $ref = ref $buf ? $buf : \$buf;

    open(my $fh, '<', $ref) or die "Could not open buffer: $!\n";
    $self->_load($fh, $pass, $args);
}

sub _load {
    my ($self, $fh, $pass, $args) = @_;

    $self = $self->new($args) if !ref $self;

    my $unlock = defined $args->{auto_lock} ? !$args->{auto_lock} : !$self->auto_lock;

    $self->kdbx->load_handle($fh, $pass);
    $self->kdbx->unlock if $unlock;
    return $self;
}


sub parse_header {
    my ($self, $buf) = @_;

    open(my $fh, '<:raw', \$buf) or die "Could not open buffer: $!\n";

    # detect filetype and version
    my $loader = File::KDBX::Loader->new;
    my ($sig1, $sig2, $version) = $loader->read_magic_numbers($fh);

    if ($sig2 == KDBX_SIG2_1 || $version < KDBX_VERSION_2_0) {
        close($fh);

        load_optional('File::KeePass');
        return File::KeePass->parse_header($buf);
    }

    my %header_transform = (
        HEADER_COMMENT()                    => ['comment'],
        HEADER_CIPHER_ID()                  => ['cipher', sub { $self->_cipher_name($_[0]) }],
        HEADER_COMPRESSION_FLAGS()          => ['compression'],
        HEADER_MASTER_SEED()                => ['seed_rand'],
        HEADER_TRANSFORM_SEED()             => ['seed_key'],
        HEADER_TRANSFORM_ROUNDS()           => ['rounds'],
        HEADER_ENCRYPTION_IV()              => ['enc_iv'],
        HEADER_INNER_RANDOM_STREAM_KEY()    => ['protected_stream_key'],
        HEADER_STREAM_START_BYTES()         => ['start_bytes'],
        HEADER_INNER_RANDOM_STREAM_ID()     => ['protected_stream', sub { $self->_inner_random_stream_name($_[0]) }],
        HEADER_KDF_PARAMETERS()             => ['kdf_parameters'],
        HEADER_PUBLIC_CUSTOM_DATA()         => ['public_custom_data'],
    );

    my %head;

    while (my ($type, $val) = $loader->_read_header($fh)) {
        last if $type == HEADER_END;
        my ($name, $filter) = @{$header_transform{$type} || ["$type"]};
        $head{$name} = $filter ? $filter->($val) : $val;
    }

    return \%head;
}


sub save_db {
    my ($self, $file, $pass, $head) = @_;
    die "Missing file\n" if !$file;
    die "Missing pass\n" if !$pass;

    shift if @_ % 2 == 1;
    my %args = @_;

    local $self->kdbx->{headers} = $self->_gen_headers($head);

    $args{randomize_seeds} = 0 if $head && $head->{reuse_header};

    $self->kdbx->dump_file($file, $pass, %args);
    return 1;
}


sub gen_db {
    my ($self, $pass, $head) = @_;
    die "Missing pass\n" if !$pass;

    shift if @_ % 2 == 1;
    my %args = @_;

    local $self->kdbx->{headers} = $self->_gen_headers($head);

    $args{randomize_seeds} = 0 if $head && $head->{reuse_header};

    my $dump = $self->kdbx->dump_string($pass, %args);
    return $$dump;
}

sub _gen_headers {
    my $self = shift;
    my $head = shift || {};

    my $v = $head->{'version'} || $self->header->{'version'};
    my $reuse = $head->{'reuse_header'}                        # explicit yes
                || (!exists($head->{'reuse_header'})           # not explicit no
                    && ($self->{'reuse_header'}                # explicit yes
                        || !exists($self->{'reuse_header'}))); # not explicit no
    if ($reuse) {
        ($head, my $args) = ($self->header || {}, $head);
        @$head{keys %$args} = values %$args;
    }
    $head->{'version'} = $v ||= $head->{'version'} || '1';
    delete @$head{qw(enc_iv seed_key seed_rand protected_stream_key start_bytes)} if $reuse && $reuse < 0;

    if ($head->{version} == 1) {
        $head->{enc_type} = 'rijndael';
        $head->{cipher} = 'aes';
    }

    my $temp_kdbx = File::KDBX::Loader::KDB::_convert_keepass_to_kdbx_headers($head, File::KDBX->new);
    return $temp_kdbx->headers;
}


sub header {
    my $self = shift;
    return if !exists $KDBX{$self};
    $self->{header} //= $self->_tie({}, 'Header', $self->kdbx);
}


sub groups {
    my $self = shift;
    return if !exists $KDBX{$self};
    $self->{groups} //= $self->_tie([], 'GroupList', $self->kdbx);
}


# Copied from File::KeePass - thanks paul
sub dump_groups {
    my ($self, $args, $groups) = @_;
    my $t = '';
    my %gargs; for (keys %$args) { $gargs{$2} = $args->{$1} if /^(group_(.+))$/ };
    foreach my $g ($self->find_groups(\%gargs, $groups)) {
        my $indent = '    ' x $g->{'level'};
        $t .= $indent.($g->{'expanded'} ? '-' : '+')."  $g->{'title'} ($g->{'id'}) $g->{'created'}\n";
        local $g->{'groups'}; # don't recurse while looking for entries since we are already flat
        $t .= "$indent    > $_->{'title'}\t($_->{'id'}) $_->{'created'}\n" for $self->find_entries($args, [$g]);
    }
    return $t;
}


sub add_group {
    my $self = shift;
    my $group = shift;

    my $parent = delete local $group->{group};
    $parent = $parent->{id} if ref $parent;

    $group->{expires} //= $self->default_exp;

    my $group_info = File::KDBX::Loader::KDB::_convert_keepass_to_kdbx_group($group);
    my $group_obj = $self->kdbx->add_group($group_info, group => $parent);
    return $self->_tie({}, 'Group', $group_obj);
}


# Copied from File::KeePass - thanks paul
sub find_groups {
    my ($self, $args, $groups, $level) = @_;
    my @tests = $self->finder_tests($args);
    my @groups;
    my %uniq;
    my $container = $groups || $self->groups;
    for my $g (@$container) {
        $g->{'level'} = $level || 0;
        $g->{'title'} = '' if ! defined $g->{'title'};
        $g->{'icon'}  ||= 0;
        if ($self->{'force_v2_gid'}) {
            $g->{'id'} = $self->uuid($g->{'id'}, \%uniq);
        } else {
            $g->{'id'} = irand while !defined($g->{'id'}) || $uniq{$g->{'id'}}++; # the non-v2 gid is compatible with both v1 and our v2 implementation
        }

        if (!@tests || !grep{!$_->($g)} @tests) {
            push @groups, $g;
            push @{ $self->{'__group_groups'} }, $container if $self->{'__group_groups'};
        }
        push @groups, $self->find_groups($args, $g->{'groups'}, $g->{'level'} + 1) if $g->{'groups'};
    }
    return @groups;
}


# Copied from File::KeePass - thanks paul
sub find_group {
    my $self = shift;
    local $self->{'__group_groups'} = [] if wantarray;
    my @g = $self->find_groups(@_);
    die "Found too many groups (@g)\n" if @g > 1;
    return wantarray ? ($g[0], $self->{'__group_groups'}->[0]) : $g[0];
}


sub delete_group {
    my $self = shift;
    my $group_info = shift;

    my $group = $self->find_group($group_info) or return;
    $group->{__object}->remove;
    return $group;
}


sub add_entry {
    my $self = shift;
    my $entry = shift;

    my $parent = delete local $entry->{group};
    $parent = $parent->{id} if ref $parent;

    $entry->{expires} //= $self->default_exp;

    my $entry_info = File::KDBX::Loader::KDB::_convert_keepass_to_kdbx_entry($entry);
    $parent = $self->kdbx->root->groups->[0] if !$parent && $self->kdbx->_has_implicit_root;
    my $entry_obj = $self->kdbx->add_entry($entry_info, group => $parent);
    return $self->_tie({}, 'Entry', $entry_obj);
}


# Copied from File::KeePass - thanks paul
sub find_entries {
    my ($self, $args, $groups) = @_;
    local @{ $args }{'expires gt', 'active'} = ($self->now, undef) if $args->{'active'};
    my @tests = $self->finder_tests($args);
    my @entries;
    foreach my $g ($self->find_groups({}, $groups)) {
        foreach my $e (@{ $g->{'entries'} || [] }) {
            local $e->{'group_id'}    = $g->{'id'};
            local $e->{'group_title'} = $g->{'title'};
            if (!@tests || !grep{!$_->($e)} @tests) {
                push @entries, $e;
                push @{ $self->{'__entry_groups'} }, $g if $self->{'__entry_groups'};
            }
        }
    }
    return @entries;
}


# Copied from File::KeePass - thanks paul
sub find_entry {
    my $self = shift;
    local $self->{'__entry_groups'} = [] if wantarray;
    my @e = $self->find_entries(@_);
    die "Found too many entries (@e)\n" if @e > 1;
    return wantarray ? ($e[0], $self->{'__entry_groups'}->[0]) : $e[0];
}


sub delete_entry {
    my $self = shift;
    my $entry_info = shift;

    my $entry = $self->find_entry($entry_info) or return;
    $entry->{__object}->remove;
    return $entry;
}

##############################################################################


# Copied from File::KeePass - thanks paul
sub finder_tests {
    my ($self, $args) = @_;
    my @tests;
    foreach my $key (keys %{ $args || {} }) {
        next if ! defined $args->{$key};
        my ($field, $op) = ($key =~ m{ ^ (\w+) \s* (|!|=|!~|=~|gt|lt) $ }x) ? ($1, $2) : die "Invalid find match criteria \"$key\"\n";
        push @tests,  (!$op || $op eq '=') ? sub {  defined($_[0]->{$field}) && $_[0]->{$field} eq $args->{$key} }
                    : ($op eq '!')         ? sub { !defined($_[0]->{$field}) || $_[0]->{$field} ne $args->{$key} }
                    : ($op eq '=~')        ? sub {  defined($_[0]->{$field}) && $_[0]->{$field} =~ $args->{$key} }
                    : ($op eq '!~')        ? sub { !defined($_[0]->{$field}) || $_[0]->{$field} !~ $args->{$key} }
                    : ($op eq 'gt')        ? sub {  defined($_[0]->{$field}) && $_[0]->{$field} gt $args->{$key} }
                    : ($op eq 'lt')        ? sub {  defined($_[0]->{$field}) && $_[0]->{$field} lt $args->{$key} }
                    : die "Unknown op \"$op\"\n";
    }
    return @tests;
}


sub default_exp { $_[0]->{default_exp} || '2999-12-31 23:23:59' }


# Copied from File::KeePass - thanks paul
sub now {
    my ($self, $time) = @_;
    my ($sec, $min, $hour, $day, $mon, $year) = gmtime($time || time);
    return sprintf '%04d-%02d-%02d %02d:%02d:%02d', $year+1900, $mon+1, $day, $hour, $min, $sec;
}

sub encode_base64 { encode_b64($_[1]) }
sub decode_base64 { decode_b64($_[1]) }

sub gen_uuid { generate_uuid(printable => 1) }

# Copied from File::KeePass - thanks paul
sub uuid {
    my ($self, $id, $uniq) = @_;
    $id = $self->gen_uuid if !defined($id) || !length($id);
    return $uniq->{$id} ||= do {
        if (length($id) != 16) {
            $id = substr($self->encode_base64($id), 0, 16) if $id !~ /^\d+$/ || $id > 2**32-1;
            $id = sprintf '%016s', $id if $id ne '0';
        }
        $id = $self->gen_uuid while $uniq->{$id}++;
        $id;
    };
}

##############################################################################


sub auto_lock {
    my $self = shift;
    $self->{auto_lock} = shift if @_;
    $self->{auto_lock} //= 1;
}


sub is_locked { $_[0]->kdbx->is_locked }


sub lock { $_[0]->kdbx->lock }


sub unlock { $_[0]->kdbx->unlock }


sub locked_entry_password {
    my $self = shift;
    my $entry = shift;

    $self->is_locked or die "Passwords are not locked\n";

    $entry = $self->find_entry({id => $entry}) if !ref $entry;
    return if !$entry;

    my $entry_obj = $entry->{__object} or return;
    return $entry_obj->string_peek('Password');
}

##############################################################################

sub _tie {
    my $self    = shift;
    my $ref     = shift // \my %h;
    my $class   = shift;
    my $obj     = shift;

    my $cache = $TIED{$self} //= {};

    $class = __PACKAGE__."::Tie::$class" if $class !~ s/^\+//;
    my $key = "$class:" . Hash::Util::FieldHash::id($obj);
    my $hit = $cache->{$key};
    return $hit if defined $hit;

    load $class;
    tie((ref $ref eq 'ARRAY' ? @$ref : %$ref), $class, $obj, @_, $self);
    $hit = $cache->{$key} = $ref;
    weaken $cache->{$key};
    return $hit;
}

### convert datetime from KDBX to KeePass format
sub _decode_datetime {
    local $_ = shift or return;
    return $_->strftime('%Y-%m-%d %H:%M:%S');
}

### convert datetime from KeePass to KDBX format
sub _encode_datetime {
    local $_ = shift or return;
    return Time::Piece->strptime($_, '%Y-%m-%d %H:%M:%S');
}

### convert UUID from KeePass to KDBX format
sub _encode_uuid {
    local $_ = shift // return;
    # Group IDs in KDB files are 32-bit integers
    return sprintf('%016x', $_) if length($_) != 16 && looks_like_number($_);
    return $_;
}

### convert tristate from KDBX to KeePass format
sub _decode_tristate {
    local $_ = shift // return;
    return $_ ? 1 : 0;
}

### convert tristate from KeePass to KDBX format
sub _encode_tristate {
    local $_ = shift // return;
    return boolean($_);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::KeePass::KDBX - Read and write KDBX files (using the File::KDBX backend)

=head1 VERSION

version 0.902

=head1 SYNOPSIS

    use File::KeePass::KDBX;

    my $k = File::KeePass::KDBX->new($kdbx);
    # OR
    my $k = File::KeePass::KDBX->load_db($filepath, $password);

    print Dumper $k->header;
    print Dumper $k->groups; # passwords are locked

    $k->unlock;
    print Dumper $k->groups; # passwords are now visible

See L<File::KeePass> for a more complete synopsis.

=head1 DESCRIPTION

This is a L<File::KeePass> compatibility shim for L<File::KDBX>. It presents the same interface as
B<File::KeePass> (mostly, see L</"Discrepancies">) but uses B<File::KDBX> for database storage, file parsing,
etc. It is meant to be a drop-in replacement for B<File::KeePass>. Documentation I<here> might be somewhat
thin, so just refer to the B<File::KeePass> documentation since everything should look the same.

Unlike B<File::KDBX> itself, I<this> module is EXPERIMENTAL. How it works might change in the future --
although by its nature it will aim to be as compatible as possible with the B<File::KeePass> interface, so
it's stable enough to start using without fear of interface changes. Just don't depend on any of its guts
(which you shouldn't do even if it were completely "stable").

B<File::KeePass::KDBX> incorporates some of the code from B<File::KeePass> but it is not a required dependency
and need not be installed for basic functionality. If B<File::KeePass> is installed, it will be used as
a backend parser and generator for working with older KDB (KeePass 1) files since B<File::KDBX> has no native
KDB parser.

=head1 ATTRIBUTES

=head2 kdbx

    $kdbx = $k->kdbx;
    $k->kdbx($kdbx);

Get or set the L<File::KDBX> instance. The C<File::KDBX> is the object that actually contains the database
data, so setting this will implicitly replace all of the data with data from the new database.

Getting the C<File::KDBX> associated with a C<File::KeePass::KDBX> grants you access to new functionality that
C<File::KeePass> doesn't have any interface for, including:

=over 4

=item *

KDBX4-exclusive data (e.g. KDF parameters and public custom data headers)

=item *

L<File::KDBX/Placeholders>

=item *

One-time passwords

=item *

Search using "Simple Expressions"

=item *

and more

=back

=head2 default_exp

    $string = $k->default_exp;

Get the default value to use as the expiry time.

=head2 auto_lock

Get and set whether the database will be locked initially after load. Regardless, the database can always be
manually locked and unlocked at any time.

See L<File::KeePass/auto_lock>.

=head1 METHODS

=head2 new

    $k = File::KeePass::KDBX->new(%attributes);
    $k = File::KeePass::KDBX->new($kdbx);
    $k = File::KeePass::KDBX->new($keepass);

Construct a new KeePass 2 database from a set of attributes, a L<File::KDBX> instance or a L<File::KeePass>
instance.

=head2 clone

    $k_copy = $k->clone;
    OR
    $k_copy = File::KeePass::KDBX->new($k);

Make a copy.

=head2 clear

    $k->clear;

Reset the database to a freshly initialized state.

See L<File::KeePass/clear>.

=head2 to_fkp

    $fkp = $k->to_fkp;

Convert a L<File::KeePass::KDBX> to a L<File::KeePass>. The resulting object is a separate copy of the
database; each can be modified independently.

=head2 from_fkp

    $k = File::KeePass::KDBX->from_fkp($fkp);

Convert a L<File::KeePass> to a L<File::KeePass::KDBX>. The resulting object is a separate copy of the
database; each can be modified independently.

=head2 load_db

    $k = $k->load_db($filepath, $key);
    $k = File::KeePass::KDBX->load_db($filepath, $key, \%args);

Load a database from a file. C<$key> is a master key, typically a password or passphrase and might also
include a keyfile path (e.g. C<[$password, $keyfile]>). C<%args> are the same as for L</new>.

See L<File::KeePass/load_db>.

=head2 parse_db

    $k = $k->parse_db($string, $key);
    $k = File::KeePass::KDBX->parse_db($string, $key, \%args);

Load a database from a string. C<$key> is a master key, typically a password or passphrase and might also
include a keyfile path (e.g. C<[$password, $keyfile]>). C<%args> are the same as for L</new>.

See L<File::KeePass/parse_db>.

=head2 parse_header

    \%head = $k->parse_header($string);

Parse only the header.

See L<File::KeePass/parse_header>.

=head2 save_db

    $k->save_db($filepath, $key);

Save the database to a file. C<$key> is a master key, typically a password or passphrase and might also
include a keyfile path (e.g. C<[$password, $keyfile]>).

See L<File::KeePass/save_db>.

=head2 gen_db

    $db_string = $k->gen_db($key);

Save the database to a string. C<$key> is a master key, typically a password or passphrase and might also
include a keyfile path (e.g. C<[$password, $keyfile]>).

See L<File::KeePass/gen_db>.

=head2 header

    \%header = $k->header;

Get the database file headers and KDBX metadata.

See L<File::KeePass/header>.

=head2 groups

    \@groups = $k->groups;

Get the groups and entries stored in a database. This is the same data that L<File::KDBX/groups> provides but
in a shape compatible with L<File::KeePass/groups>.

=head2 dump_groups

    $string = $k->dump_groups;
    $string = $k->dump_groups(\%query);

Get a string representation of the groups in the database.

See L<File::KeePass/dump_groups>.

=head2 add_group

    $group = $k->add_group(\%group_info);

Add a new group.

See L<File::KeePass/add_group>.

=head2 find_groups

    @groups = $k->find_groups(\%query);

Find groups.

See L<File::KeePass/find_groups>.

=head2 find_group

    $group = $k->find_group(\%query);

Find one group. If the query matches more than one group, an exception is thrown. If there is no matching
group, C<undef> is returned

See L<File::KeePass/find_group>.

=head2 delete_group

    $group = $k->delete_group(\%query);

Delete a group.

See L<File::KeePass/delete_group>.

=head2 add_entry

    $entry = $k->add_entry(\%entry_info);

Add a new entry.

See L<File::KeePass/add_entry>.

=head2 find_entries

    @entries = $k->find_entries(\%query);

Find entries.

See L<File::KeePass/find_entries>.

=head2 find_entry

    $entry = $k->find_entry(\%query);

Find one entry. If the query matches more than one entry, an exception is thrown. If there is no matching
entry, C<undef> is returned

See L<File::KeePass/find_entry>.

=head2 delete_entry

    $entry = $k->delete_entry(\%query);

Delete an entry.

See L<File::KeePass/delete_entry>.

=head2 finder_tests

    @tests = $k->finder_tests(\%query);

This is the query engine used to find groups and entries.

See L<File::KeePass/finder_tests>.

=head2 now

    $string = $k->now;

Get a timestamp representing the current date and time.

=head2 is_locked

    $bool = $k->is_locked;

Get whether or not a database is locked (i.e. memory-protected passwords).

See L<File::KeePass/is_locked>.

=head2 lock

    $k->lock;

Lock a database.

See L<File::KeePass/lock>.

=head2 unlock

    $k->unlock;

Unlock a database.

See L<File::KeePass/unlock>.

=head2 locked_entry_password

    $password = $k->locked_entry_password($entry);

Get a memory-protected password.

See L<File::KeePass/locked_entry_password>.

=for Pod::Coverage STORABLE_freeze STORABLE_thaw decode_base64 encode_base64 gen_uuid now uuid

=head1 CAVEATS

This shim uses L<perltie> magics. Some data structures look and act like regular hashes and arrays (mostly),
but you might notice some unexpected magical things happen, like hash fields that populate themselves. The
magic is only there to make matching the B<File::KeePass> interface possible, since that interface assumes
some amount of interaction with unblessed data structures. Some effort was made to at least hide the magic
where reasonable; any magical behavior is incidental and not considered a feature.

You should expect some considerable overhead which makes this module generally slower than using either
B<File::KeePass> or B<File::KDBX> directly. In some cases this might be due to an inefficient implementation
in the shim, but largely it is the cost of transparent compatibility.

If performance is critical and you still don't want to rewrite your code to use B<File::KDBX> directly but do
want to take advantage of some of the new stuff, there is also the option to go part way. The strategy here is
to use B<File::KeePass::KDBX> to load a database and then immediately convert it to a B<File::KeePass> object.
Use that object without any runtime overhead, and then if and when you're ready to save the database or use
any other B<File::KDBX> feature, "upgrade" it back into a B<File::KeePass::KDBX> object. This strategy would
require modest code modifications to your application, to change:

    my $k = File::KeePass->new('database.kdbx', 'masterpw');

to this:

    my $k = File::KeePass::KDBX->load_db('database.kdbx', 'masterpw')->to_fkp;
    # $k is a normal File::KeePass

and change:

    $k->save_db('database.kdbx', 'masterpw');

to this:

    File::KeePass::KDBX->from_fkp($k)->save_db('database.kdbx', 'masterpw');

This works because B<File::KeePass::KDBX> provides methods L</to_fkp> and L</from_fkp> for converting to and
from B<File::KeePass>. L</new> also works instead of L</from_fkp>.

=head2 Discrepancies

This shim I<is> supposed to be a drop-in replacement for L<File::KeePass>. If you're sticking to the
B<File::KeePass> public interface you probably won't have to rewrite any code. If you do, it could be
considered a B<File::KeePass::KDBX> bug. But there are some differences that some code might notice and could
even get tripped up on:

B<File::KeePass::KDBX> does not provide any of the L<File::KeePass/"UTILITY METHODS"> or
L<File::KeePass/"OTHER METHODS"> unless incidentally, with two exceptions: L</now> and L</default_exp>.
I judge these other methods to not be useful for I<users> of B<File::KeePass> and so probably aren't used by
anyone, but if I'm wrong you can get them by using B<File::KeePass>:

    use File::KeePass;  # must use before File::KeePass::KDBX
    use File::KeePass::KDBX;

Using both B<File::KeePass> and B<File::KeePass::KDBX> in this order will make the latter a proper subclass of
the former, so all the utility methods will be available via inheritance. You might also need to do this if
the answer to C<< File::KeePass::KDBX->new->isa('File::KeePass') >> is important to your code.

B<File::KeePass::KDBX> does not take any pains to replicate
L<File::KeePass bugs|https://rt.cpan.org/Public/Dist/Display.html?Name=File-KeePass>. If your code has any
workarounds, you might need or want to undo those. The issues known to be fixed (or not applicable) by using
B<File::KeePass::KDBX> are:
L<#85012|https://rt.cpan.org/Ticket/Display.html?id=85012>,
L<#82582|https://rt.cpan.org/Ticket/Display.html?id=82582>,
L<#124531|https://rt.cpan.org/Ticket/Display.html?id=124531>,
L<#123330|https://rt.cpan.org/Ticket/Display.html?id=123330>,
L<#120224|https://rt.cpan.org/Ticket/Display.html?id=120224>,
L<#117836|https://rt.cpan.org/Ticket/Display.html?id=117836>,
L<#97055|https://rt.cpan.org/Ticket/Display.html?id=97055>,
L<#96049|https://rt.cpan.org/Ticket/Display.html?id=96049>,
L<#94753|https://rt.cpan.org/Ticket/Display.html?id=94753> and
L<#87109|https://rt.cpan.org/Ticket/Display.html?id=87109>.

B<File::KeePass> provides the C<header_size> field in the L</header>, which is the size of the file header in
number of bytes. B<File::KeePass::KDBX> does not.

B<File::KeePass> supports a C<keep_xml> option on L</load_db> to retain a copy of the XML of a KDBX file from
the parser as a string. B<File::KeePass::KDBX> does not support this option. To do something similar with
B<File::KDBX>:

    my $kdbx = File::KDBX->load($filepath, $key, inner_format => 'Raw');
    my $xml = $kdbx->raw;

There might be idiosyncrasies related to default values and when they're set. Fields within data structures
might exist but be undefined in one where they just don't exist in the other. You might need to check for
values using L<perlfunc/defined> instead of L<perlfunc/exists>.

B<File::KeePass::KDBX> might have slightly different error handling semantics. It might be stricter or fail
earlier in some cases. For example, setting a date & time or UUID with an invalid format might fail
immediately rather than later on in a query or at file generation. To achieve perfect consistency, you might
need to validate your inputs and handle errors before passing them to B<File::KeePass::KDBX>.

Some methods have different performance profiles from their B<File::KeePass> counterparts. Operations that are
constant time in B<File::KeePass> might be linear in B<File::KeePass::KDBX>, for example. Or some things in
B<File::KeePass::KDBX> might be faster than B<File::KeePass>. Of course you are not likely to detect any
differences unless you work with very large databases, and I don't know of any application where large KDBX
databases are common. I don't think I<any> KDBX implementation is optimized for large databases.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/chazmcgarvey/File-KeePass-KDBX/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Charles McGarvey <ccm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Charles McGarvey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
