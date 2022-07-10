package File::KDBX;
# ABSTRACT: Encrypted database to store secret text and files

use 5.010;
use warnings;
use strict;

use Crypt::Digest qw(digest_data);
use Crypt::PRNG qw(random_bytes);
use Devel::GlobalDestruction;
use File::KDBX::Constants qw(:all :icon);
use File::KDBX::Error;
use File::KDBX::Safe;
use File::KDBX::Util qw(:class :coercion :empty :search :uuid erase simple_expression_query snakify);
use Hash::Util::FieldHash qw(fieldhashes);
use List::Util qw(any first);
use Ref::Util qw(is_ref is_arrayref is_plain_hashref);
use Scalar::Util qw(blessed);
use Time::Piece 1.33;
use boolean;
use namespace::clean;

our $VERSION = '0.904'; # VERSION
our $WARNINGS = 1;

fieldhashes \my (%SAFE, %KEYS);


sub new {
    my $class = shift;

    # copy constructor
    return $_[0]->clone if @_ == 1 && blessed $_[0] && $_[0]->isa($class);

    my $self = bless {}, $class;
    $self->init(@_);
    $self->_set_nonlazy_attributes if empty $self;
    return $self;
}

sub DESTROY { local ($., $@, $!, $^E, $?); !in_global_destruction and $_[0]->reset }


sub init {
    my $self = shift;
    my %args = @_;

    @$self{keys %args} = values %args;

    return $self;
}


sub reset {
    my $self = shift;
    erase $self->headers->{+HEADER_INNER_RANDOM_STREAM_KEY};
    erase $self->inner_headers->{+INNER_HEADER_INNER_RANDOM_STREAM_KEY};
    erase $self->{raw};
    %$self = ();
    $self->_remove_safe;
    return $self;
}


sub clone {
    my $self = shift;
    require Storable;
    return Storable::dclone($self);
}

sub STORABLE_freeze {
    my $self    = shift;
    my $cloning = shift;

    my $copy = {%$self};

    return '', $copy, $KEYS{$self} // (), $SAFE{$self} // ();
}

sub STORABLE_thaw {
    my $self    = shift;
    my $cloning = shift;
    shift;
    my $clone   = shift;
    my $key     = shift;
    my $safe    = shift;

    @$self{keys %$clone} = values %$clone;
    $KEYS{$self} = $key;
    $SAFE{$self} = $safe;

    # Dualvars aren't cloned as dualvars, so coerce the compression flags.
    $self->compression_flags($self->compression_flags);

    $self->objects(history => 1)->each(sub { $_->kdbx($self) });
}

##############################################################################


sub load        { shift->_loader->load(@_) }
sub load_string { shift->_loader->load_string(@_) }
sub load_file   { shift->_loader->load_file(@_) }
sub load_handle { shift->_loader->load_handle(@_) }

sub _loader {
    my $self = shift;
    $self = $self->new if !ref $self;
    require File::KDBX::Loader;
    File::KDBX::Loader->new(kdbx => $self);
}


sub dump        { shift->_dumper->dump(@_) }
sub dump_string { shift->_dumper->dump_string(@_) }
sub dump_file   { shift->_dumper->dump_file(@_) }
sub dump_handle { shift->_dumper->dump_handle(@_) }

sub _dumper {
    my $self = shift;
    $self = $self->new if !ref $self;
    require File::KDBX::Dumper;
    File::KDBX::Dumper->new(kdbx => $self);
}

##############################################################################


sub user_agent_string {
    require Config;
    sprintf('%s/%s (%s/%s; %s/%s; %s)',
        __PACKAGE__, $VERSION, @Config::Config{qw(package version osname osvers archname)});
}

has sig1            => KDBX_SIG1,        coerce => \&to_number;
has sig2            => KDBX_SIG2_2,      coerce => \&to_number;
has version         => KDBX_VERSION_3_1, coerce => \&to_number;
has headers         => {};
has inner_headers   => {};
has meta            => {};
has binaries        => {};
has deleted_objects => {};
has raw             => coerce => \&to_string;

# HEADERS
has 'headers.comment'               => '',                          coerce => \&to_string;
has 'headers.cipher_id'             => CIPHER_UUID_CHACHA20,        coerce => \&to_uuid;
has 'headers.compression_flags'     => COMPRESSION_GZIP,            coerce => \&to_compression_constant;
has 'headers.master_seed'           => sub { random_bytes(32) },    coerce => \&to_string;
has 'headers.encryption_iv'         => sub { random_bytes(16) },    coerce => \&to_string;
has 'headers.stream_start_bytes'    => sub { random_bytes(32) },    coerce => \&to_string;
has 'headers.kdf_parameters'        => sub {
    +{
        KDF_PARAM_UUID()        => KDF_UUID_AES,
        KDF_PARAM_AES_ROUNDS()  => $_[0]->headers->{+HEADER_TRANSFORM_ROUNDS} // KDF_DEFAULT_AES_ROUNDS,
        KDF_PARAM_AES_SEED()    => $_[0]->headers->{+HEADER_TRANSFORM_SEED} // random_bytes(32),
    };
};
# has 'headers.transform_seed'            => sub { random_bytes(32) };
# has 'headers.transform_rounds'          => 100_000;
# has 'headers.inner_random_stream_key'   => sub { random_bytes(32) }; # 64 ?
# has 'headers.inner_random_stream_id'    => STREAM_ID_CHACHA20;
# has 'headers.public_custom_data'        => {};

# META
has 'meta.generator'                        => '',                          coerce => \&to_string;
has 'meta.header_hash'                      => '',                          coerce => \&to_string;
has 'meta.database_name'                    => '',                          coerce => \&to_string;
has 'meta.database_name_changed'            => sub { gmtime },              coerce => \&to_time;
has 'meta.database_description'             => '',                          coerce => \&to_string;
has 'meta.database_description_changed'     => sub { gmtime },              coerce => \&to_time;
has 'meta.default_username'                 => '',                          coerce => \&to_string;
has 'meta.default_username_changed'         => sub { gmtime },              coerce => \&to_time;
has 'meta.maintenance_history_days'         => HISTORY_DEFAULT_MAX_AGE,     coerce => \&to_number;
has 'meta.color'                            => '',                          coerce => \&to_string;
has 'meta.master_key_changed'               => sub { gmtime },              coerce => \&to_time;
has 'meta.master_key_change_rec'            => -1,                          coerce => \&to_number;
has 'meta.master_key_change_force'          => -1,                          coerce => \&to_number;
# has 'meta.memory_protection'                => {};
has 'meta.custom_icons'                     => [];
has 'meta.recycle_bin_enabled'              => true,                        coerce => \&to_bool;
has 'meta.recycle_bin_uuid'                 => UUID_NULL,                   coerce => \&to_uuid;
has 'meta.recycle_bin_changed'              => sub { gmtime },              coerce => \&to_time;
has 'meta.entry_templates_group'            => UUID_NULL,                   coerce => \&to_uuid;
has 'meta.entry_templates_group_changed'    => sub { gmtime },              coerce => \&to_time;
has 'meta.last_selected_group'              => UUID_NULL,                   coerce => \&to_uuid;
has 'meta.last_top_visible_group'           => UUID_NULL,                   coerce => \&to_uuid;
has 'meta.history_max_items'                => HISTORY_DEFAULT_MAX_ITEMS,   coerce => \&to_number;
has 'meta.history_max_size'                 => HISTORY_DEFAULT_MAX_SIZE,    coerce => \&to_number;
has 'meta.settings_changed'                 => sub { gmtime },              coerce => \&to_time;
# has 'meta.binaries'                         => {};
# has 'meta.custom_data'                      => {};

has 'memory_protection.protect_title'       => false,   coerce => \&to_bool;
has 'memory_protection.protect_username'    => false,   coerce => \&to_bool;
has 'memory_protection.protect_password'    => true,    coerce => \&to_bool;
has 'memory_protection.protect_url'         => false,   coerce => \&to_bool;
has 'memory_protection.protect_notes'       => false,   coerce => \&to_bool;
# has 'memory_protection.auto_enable_visual_hiding'   => false;

my @ATTRS = (
    HEADER_TRANSFORM_SEED,
    HEADER_TRANSFORM_ROUNDS,
    HEADER_INNER_RANDOM_STREAM_KEY,
    HEADER_INNER_RANDOM_STREAM_ID,
    HEADER_PUBLIC_CUSTOM_DATA,
);
sub _set_nonlazy_attributes {
    my $self = shift;
    $self->$_ for list_attributes(ref $self), @ATTRS;
}


sub memory_protection {
    my $self = shift;
    $self->{meta}{memory_protection} = shift if @_ == 1 && is_plain_hashref($_[0]);
    return $self->{meta}{memory_protection} //= {} if !@_;

    my $string_key = shift;
    my $key = 'protect_' . lc($string_key);

    $self->meta->{memory_protection}{$key} = shift if @_;
    $self->meta->{memory_protection}{$key};
}


sub minimum_version {
    my $self = shift;

    return KDBX_VERSION_4_1 if any {
        nonempty $_->{last_modification_time}
    } values %{$self->custom_data};

    return KDBX_VERSION_4_1 if any {
        nonempty $_->{name} || nonempty $_->{last_modification_time}
    } @{$self->custom_icons};

    return KDBX_VERSION_4_1 if $self->groups->next(sub {
        nonempty $_->previous_parent_group ||
        nonempty $_->tags ||
        (any { nonempty $_->{last_modification_time} } values %{$_->custom_data})
    });

    return KDBX_VERSION_4_1 if $self->entries(history => 1)->next(sub {
        nonempty $_->previous_parent_group ||
        (defined $_->quality_check && !$_->quality_check) ||
        (any { nonempty $_->{last_modification_time} } values %{$_->custom_data})
    });

    return KDBX_VERSION_4_0 if $self->kdf->uuid ne KDF_UUID_AES;

    return KDBX_VERSION_4_0 if nonempty $self->public_custom_data;

    return KDBX_VERSION_4_0 if $self->objects->next(sub {
        nonempty $_->custom_data
    });

    return KDBX_VERSION_3_1;
}

##############################################################################


sub root {
    my $self = shift;
    if (@_) {
        $self->{root} = $self->_wrap_group(@_);
        $self->{root}->kdbx($self);
    }
    $self->{root} //= $self->_implicit_root;
    return $self->_wrap_group($self->{root});
}

# Called by File::KeePass::KDBX so that a File::KDBX an be treated as a File::KDBX::Group in that both types
# can have subgroups. File::KDBX already has a `groups' method that does something different from the
# File::KDBX::Groups `groups' method.
sub _kpx_groups {
    my $self = shift;
    return [] if !$self->{root};
    return $self->_has_implicit_root ? $self->root->groups : [$self->root];
}

sub _has_implicit_root {
    my $self = shift;
    my $root = $self->root;
    my $temp = __PACKAGE__->_implicit_root;
    # If an implicit root group has been changed in any significant way, it is no longer implicit.
    return $root->name eq $temp->name &&
        $root->is_expanded ^ $temp->is_expanded &&
        $root->notes eq $temp->notes &&
        !@{$root->entries} &&
        !defined $root->custom_icon_uuid &&
        !keys %{$root->custom_data} &&
        $root->icon_id == $temp->icon_id &&
        $root->expires ^ $temp->expires &&
        $root->default_auto_type_sequence eq $temp->default_auto_type_sequence &&
        !defined $root->enable_auto_type &&
        !defined $root->enable_searching;
}

sub _implicit_root {
    my $self = shift;
    require File::KDBX::Group;
    return File::KDBX::Group->new(
        name        => 'Root',
        is_expanded => true,
        notes       => 'Added as an implicit root group by '.__PACKAGE__.'.',
        ref $self ? (kdbx => $self) : (),
    );
}


sub trace_lineage {
    my $self    = shift;
    my $object  = shift;
    return $object->lineage(@_);
}

sub _trace_lineage {
    my $self    = shift;
    my $object  = shift;
    my @lineage = @_;

    push @lineage, $self->root if !@lineage;
    my $base = $lineage[-1] or return [];

    my $uuid = $object->uuid;
    return \@lineage if any { $_->uuid eq $uuid } @{$base->groups}, @{$base->entries};

    for my $subgroup (@{$base->groups}) {
        my $result = $self->_trace_lineage($object, @lineage, $subgroup);
        return $result if $result;
    }
}


sub recycle_bin {
    my $self = shift;
    if (my $group = shift) {
        $self->recycle_bin_uuid($group->uuid);
        return $group;
    }
    my $group;
    my $uuid = $self->recycle_bin_uuid;
    $group = $self->groups->grep(uuid => $uuid)->next if $uuid ne UUID_NULL;
    if (!$group && $self->recycle_bin_enabled) {
        $group = $self->add_group(
            name                => 'Recycle Bin',
            icon_id             => ICON_TRASHCAN_FULL,
            enable_auto_type    => false,
            enable_searching    => false,
        );
        $self->recycle_bin_uuid($group->uuid);
    }
    return $group;
}


sub entry_templates {
    my $self = shift;
    if (my $group = shift) {
        $self->entry_templates_group($group->uuid);
        return $group;
    }
    my $uuid = $self->entry_templates_group;
    return if $uuid eq UUID_NULL;
    return $self->groups->grep(uuid => $uuid)->next;
}


sub last_selected {
    my $self = shift;
    if (my $group = shift) {
        $self->last_selected_group($group->uuid);
        return $group;
    }
    my $uuid = $self->last_selected_group;
    return if $uuid eq UUID_NULL;
    return $self->groups->grep(uuid => $uuid)->next;
}


sub last_top_visible {
    my $self = shift;
    if (my $group = shift) {
        $self->last_top_visible_group($group->uuid);
        return $group;
    }
    my $uuid = $self->last_top_visible_group;
    return if $uuid eq UUID_NULL;
    return $self->groups->grep(uuid => $uuid)->next;
}

##############################################################################


sub add_group {
    my $self    = shift;
    my $group   = @_ % 2 == 1 ? shift : undef;
    my %args    = @_;

    # find the right group to add the group to
    my $parent = delete $args{group} // $self->root;
    $parent = $self->groups->grep({uuid => $parent})->next if !ref $parent;
    $parent or throw 'Invalid group';

    return $parent->add_group(defined $group ? $group : (), %args, kdbx => $self);
}

sub _wrap_group {
    my $self  = shift;
    my $group = shift;
    require File::KDBX::Group;
    return File::KDBX::Group->wrap($group, $self);
}


sub groups {
    my $self = shift;
    my %args = @_ % 2 == 0 ? @_ : (base => shift, @_);
    my $base = delete $args{base} // $self->root;

    return $base->all_groups(%args);
}

##############################################################################


sub add_entry {
    my $self    = shift;
    my $entry   = @_ % 2 == 1 ? shift : undef;
    my %args    = @_;

    # find the right group to add the entry to
    my $parent = delete $args{group} // $self->root;
    $parent = $self->groups->grep({uuid => $parent})->next if !ref $parent;
    $parent or throw 'Invalid group';

    return $parent->add_entry(defined $entry ? $entry : (), %args, kdbx => $self);
}

sub _wrap_entry {
    my $self  = shift;
    my $entry = shift;
    require File::KDBX::Entry;
    return File::KDBX::Entry->wrap($entry, $self);
}


sub entries {
    my $self = shift;
    my %args = @_ % 2 == 0 ? @_ : (base => shift, @_);
    my $base = delete $args{base} // $self->root;

    return $base->all_entries(%args);
}

##############################################################################


sub objects {
    my $self = shift;
    my %args = @_ % 2 == 0 ? @_ : (base => shift, @_);
    my $base = delete $args{base} // $self->root;

    return $base->all_objects(%args);
}

sub __iter__ { $_[0]->objects }

##############################################################################


sub custom_icon {
    my $self = shift;
    my %args = @_     == 2 ? (uuid => shift, data => shift)
             : @_ % 2 == 1 ? (uuid => shift, @_) : @_;

    if (!$args{uuid} && !$args{data}) {
        my %standard = (uuid => 1, data => 1, name => 1, last_modification_time => 1);
        my @other_keys = grep { !$standard{$_} } keys %args;
        if (@other_keys == 1) {
            my $key = $args{key} = $other_keys[0];
            $args{data} = delete $args{$key};
        }
    }

    my $uuid = $args{uuid} or throw 'Must provide a custom icon UUID to access';
    my $icon = (first { $_->{uuid} eq $uuid } @{$self->custom_icons}) // do {
        push @{$self->custom_icons}, my $i = { uuid => $uuid };
        $i;
    };

    my $fields = \%args;
    $fields = $args{data} if is_plain_hashref($args{data});

    while (my ($field, $value) = each %$fields) {
        $icon->{$field} = $value;
    }
    return $icon;
}


sub custom_icon_data {
    my $self = shift;
    my $uuid = shift // return;
    my $icon = first { $_->{uuid} eq $uuid } @{$self->custom_icons} or return;
    return $icon->{data};
}


sub add_custom_icon {
    my $self = shift;
    my %args = @_ % 2 == 1 ? (data => shift, @_) : @_;

    defined $args{data} or throw 'Must provide image data';

    my $uuid = $args{uuid} // generate_uuid;
    push @{$self->custom_icons}, {
        @_,
        uuid    => $uuid,
        data    => $args{data},
    };
    return $uuid;
}


sub remove_custom_icon {
    my $self = shift;
    my $uuid = shift;
    my @deleted;
    @{$self->custom_icons} = grep { $_->{uuid} eq $uuid ? do { push @deleted, $_; 0 } : 1 }
        @{$self->custom_icons};
    $self->add_deleted_object($uuid) if @deleted;
    return @deleted;
}

##############################################################################


sub custom_data {
    my $self = shift;
    $self->{meta}{custom_data} = shift if @_ == 1 && is_plain_hashref($_[0]);
    return $self->{meta}{custom_data} //= {} if !@_;

    my %args = @_     == 2 ? (key => shift, value => shift)
             : @_ % 2 == 1 ? (key => shift, @_) : @_;

    if (!$args{key} && !$args{value}) {
        my %standard = (key => 1, value => 1, last_modification_time => 1);
        my @other_keys = grep { !$standard{$_} } keys %args;
        if (@other_keys == 1) {
            my $key = $args{key} = $other_keys[0];
            $args{value} = delete $args{$key};
        }
    }

    my $key = $args{key} or throw 'Must provide a custom_data key to access';

    return $self->{meta}{custom_data}{$key} = $args{value} if is_plain_hashref($args{value});

    while (my ($field, $value) = each %args) {
        $self->{meta}{custom_data}{$key}{$field} = $value;
    }
    return $self->{meta}{custom_data}{$key};
}


sub custom_data_value {
    my $self = shift;
    my $data = $self->custom_data(@_) // return;
    return $data->{value};
}


sub public_custom_data {
    my $self = shift;
    $self->{headers}{+HEADER_PUBLIC_CUSTOM_DATA} = shift if @_ == 1 && is_plain_hashref($_[0]);
    return $self->{headers}{+HEADER_PUBLIC_CUSTOM_DATA} //= {} if !@_;

    my $key = shift or throw 'Must provide a public_custom_data key to access';
    $self->{headers}{+HEADER_PUBLIC_CUSTOM_DATA}{$key} = shift if @_;
    return $self->{headers}{+HEADER_PUBLIC_CUSTOM_DATA}{$key};
}

##############################################################################

# TODO

# sub merge_to {
#     my $self = shift;
#     my $other = shift;
#     my %options = @_;   # prefer_old / prefer_new
#     $other->merge_from($self);
# }

# sub merge_from {
#     my $self = shift;
#     my $other = shift;

#     die 'Not implemented';
# }


sub add_deleted_object {
    my $self = shift;
    my $uuid = shift;

    # ignore null and meta stream UUIDs
    return if $uuid eq UUID_NULL || $uuid eq '0' x 16;

    $self->deleted_objects->{$uuid} = {
        uuid            => $uuid,
        deletion_time   => scalar gmtime,
    };
}


sub remove_deleted_object {
    my $self = shift;
    my $uuid = shift;
    delete $self->deleted_objects->{$uuid};
}


sub clear_deleted_objects {
    my $self = shift;
    %{$self->deleted_objects} = ();
}

##############################################################################


sub resolve_reference {
    my $self        = shift;
    my $wanted      = shift // return;
    my $search_in   = shift;
    my $text        = shift;

    if (!defined $text) {
        $wanted =~ s/^\{REF:([^\}]+)\}$/$1/i;
        ($wanted, $search_in, $text) = $wanted =~ /^([TUPANI])\@([TUPANIO]):(.*)$/i;
    }
    $wanted && $search_in && nonempty($text) or return;

    my %fields = (
        T   => 'expand_title',
        U   => 'expand_username',
        P   => 'expand_password',
        A   => 'expand_url',
        N   => 'expand_notes',
        I   => 'uuid',
        O   => 'other_strings',
    );
    $wanted     = $fields{$wanted} or return;
    $search_in  = $fields{$search_in} or return;

    my $query = $search_in eq 'uuid' ? query($search_in => uuid($text))
                                     : simple_expression_query($text, '=~', $search_in);

    my $entry = $self->entries->grep($query)->next;
    $entry or return;

    return $entry->$wanted;
}

our %PLACEHOLDERS = (
    # 'PLACEHOLDER'       => sub { my ($entry, $arg) = @_; ... };
    'TITLE'             => sub { $_[0]->expand_title },
    'USERNAME'          => sub { $_[0]->expand_username },
    'PASSWORD'          => sub { $_[0]->expand_password },
    'NOTES'             => sub { $_[0]->expand_notes },
    'S:'                => sub { $_[0]->string_value($_[1]) },
    'URL'               => sub { $_[0]->expand_url },
    'URL:RMVSCM'        => sub { local $_ = $_[0]->url; s!^[^:/\?\#]+://!!; $_ },
    'URL:WITHOUTSCHEME' => sub { local $_ = $_[0]->url; s!^[^:/\?\#]+://!!; $_ },
    'URL:SCM'           => sub { (split_url($_[0]->url))[0] },
    'URL:SCHEME'        => sub { (split_url($_[0]->url))[0] },  # non-standard
    'URL:HOST'          => sub { (split_url($_[0]->url))[2] },
    'URL:PORT'          => sub { (split_url($_[0]->url))[3] },
    'URL:PATH'          => sub { (split_url($_[0]->url))[4] },
    'URL:QUERY'         => sub { (split_url($_[0]->url))[5] },
    'URL:HASH'          => sub { (split_url($_[0]->url))[6] },  # non-standard
    'URL:FRAGMENT'      => sub { (split_url($_[0]->url))[6] },  # non-standard
    'URL:USERINFO'      => sub { (split_url($_[0]->url))[1] },
    'URL:USERNAME'      => sub { (split_url($_[0]->url))[7] },
    'URL:PASSWORD'      => sub { (split_url($_[0]->url))[8] },
    'UUID'              => sub { local $_ = format_uuid($_[0]->uuid); s/-//g; $_ },
    'REF:'              => sub { $_[0]->kdbx->resolve_reference($_[1]) },
    'INTERNETEXPLORER'  => sub { load_optional('IPC::Cmd'); IPC::Cmd::can_run('iexplore') },
    'FIREFOX'           => sub { load_optional('IPC::Cmd'); IPC::Cmd::can_run('firefox') },
    'GOOGLECHROME'      => sub { load_optional('IPC::Cmd'); IPC::Cmd::can_run('google-chrome') },
    'OPERA'             => sub { load_optional('IPC::Cmd'); IPC::Cmd::can_run('opera') },
    'SAFARI'            => sub { load_optional('IPC::Cmd'); IPC::Cmd::can_run('safari') },
    'APPDIR'            => sub { load_optional('FindBin'); $FindBin::Bin },
    'GROUP'             => sub { my $p = $_[0]->group; $p ? $p->name : undef },
    'GROUP_PATH'        => sub { $_[0]->path },
    'GROUP_NOTES'       => sub { my $p = $_[0]->group; $p ? $p->notes : undef },
    # 'GROUP_SEL'
    # 'GROUP_SEL_PATH'
    # 'GROUP_SEL_NOTES'
    # 'DB_PATH'
    # 'DB_DIR'
    # 'DB_NAME'
    # 'DB_BASENAME'
    # 'DB_EXT'
    'ENV:'              => sub { $ENV{$_[1]} },
    'ENV_DIRSEP'        => sub { load_optional('File::Spec')->catfile('', '') },
    'ENV_PROGRAMFILES_X86'  => sub { $ENV{'ProgramFiles(x86)'} || $ENV{'ProgramFiles'} },
    # 'T-REPLACE-RX:'
    # 'T-CONV:'
    'DT_SIMPLE'         => sub { localtime->strftime('%Y%m%d%H%M%S') },
    'DT_YEAR'           => sub { localtime->strftime('%Y') },
    'DT_MONTH'          => sub { localtime->strftime('%m') },
    'DT_DAY'            => sub { localtime->strftime('%d') },
    'DT_HOUR'           => sub { localtime->strftime('%H') },
    'DT_MINUTE'         => sub { localtime->strftime('%M') },
    'DT_SECOND'         => sub { localtime->strftime('%S') },
    'DT_UTC_SIMPLE'     => sub { gmtime->strftime('%Y%m%d%H%M%S') },
    'DT_UTC_YEAR'       => sub { gmtime->strftime('%Y') },
    'DT_UTC_MONTH'      => sub { gmtime->strftime('%m') },
    'DT_UTC_DAY'        => sub { gmtime->strftime('%d') },
    'DT_UTC_HOUR'       => sub { gmtime->strftime('%H') },
    'DT_UTC_MINUTE'     => sub { gmtime->strftime('%M') },
    'DT_UTC_SECOND'     => sub { gmtime->strftime('%S') },
    # 'PICKCHARS'
    # 'PICKCHARS:'
    # 'PICKFIELD'
    # 'NEWPASSWORD'
    # 'NEWPASSWORD:'
    # 'PASSWORD_ENC'
    'HMACOTP'           => sub { $_[0]->hmac_otp },
    'TIMEOTP'           => sub { $_[0]->time_otp },
    'C:'                => sub { '' },  # comment
    # 'BASE'
    # 'BASE:'
    # 'CLIPBOARD'
    # 'CLIPBOARD-SET:'
    # 'CMD:'
);

##############################################################################


sub _safe {
    my $self = shift;
    $SAFE{$self} = shift if @_;
    $SAFE{$self};
}

sub _remove_safe { delete $SAFE{$_[0]} }

sub lock {
    my $self = shift;

    $self->_safe and return $self;

    my @strings;

    $self->entries(history => 1)->each(sub {
        push @strings, grep { $_->{protect} } values %{$_->strings}, values %{$_->binaries};
    });

    $self->_safe(File::KDBX::Safe->new(\@strings));

    return $self;
}


sub unlock {
    my $self = shift;
    my $safe = $self->_safe or return $self;

    $safe->unlock;
    $self->_remove_safe;

    return $self;
}


sub unlock_scoped {
    throw 'Programmer error: Cannot call unlock_scoped in void context' if !defined wantarray;
    my $self = shift;
    return if !$self->is_locked;
    require Scope::Guard;
    my $guard = Scope::Guard->new(sub { $self->lock });
    $self->unlock;
    return $guard;
}


sub peek {
    my $self = shift;
    my $string = shift;
    my $safe = $self->_safe or return;
    return $safe->peek($string);
}


sub is_locked { !!$_[0]->_safe }

##############################################################################

# sub check {
# - Fixer tool. Can repair inconsistencies, including:
#   - Orphaned binaries... not really a thing anymore since we now distribute binaries amongst entries
#   - Unused custom icons (OFF, data loss)
#   - Duplicate icons
#   - All data types are valid
#     - date times are correct
#     - boolean fields
#     - All UUIDs refer to things that exist
#       - previous parent group
#       - recycle bin
#       - last selected group
#       - last visible group
#   - Enforce history size limits (ON)
#   - Check headers/meta (ON)
#   - Duplicate deleted objects (ON)
#   - Duplicate window associations (OFF)
#   - Header UUIDs match known ciphers/KDFs?
# }


sub remove_empty_groups {
    my $self = shift;
    my @removed;
    $self->groups(algorithm => 'dfs')
    ->where(-true => 'is_empty')
    ->each(sub { push @removed, $_->remove });
    return @removed;
}


sub remove_unused_icons {
    my $self = shift;
    my %icons = map { $_->{uuid} => 0 } @{$self->custom_icons};

    $self->objects->each(sub { ++$icons{$_->custom_icon_uuid // ''} });

    my @removed;
    push @removed, $self->remove_custom_icon($_) for grep { $icons{$_} == 0 } keys %icons;
    return @removed;
}


sub remove_duplicate_icons {
    my $self = shift;

    my %seen;
    my %dup;
    for my $icon (@{$self->custom_icons}) {
        my $digest = digest_data('SHA256', $icon->{data});
        if (my $other = $seen{$digest}) {
            $dup{$icon->{uuid}} = $other->{uuid};
        }
        else {
            $seen{$digest} = $icon;
        }
    }

    my @removed;
    while (my ($old_uuid, $new_uuid) = each %dup) {
        $self->objects
        ->where(custom_icon_uuid => $old_uuid)
        ->each(sub { $_->custom_icon_uuid($new_uuid) });
        push @removed, $self->remove_custom_icon($old_uuid);
    }
    return @removed;
}


sub prune_history {
    my $self = shift;
    my %args = @_;

    my $max_items = $args{max_items} // $self->history_max_items // HISTORY_DEFAULT_MAX_ITEMS;
    my $max_size  = $args{max_size}  // $self->history_max_size  // HISTORY_DEFAULT_MAX_SIZE;
    my $max_age   = $args{max_age}   // $self->maintenance_history_days // HISTORY_DEFAULT_MAX_AGE;

    my @removed;
    $self->entries->each(sub {
        push @removed, $_->prune_history(
            max_items   => $max_items,
            max_size    => $max_size,
            max_age     => $max_age,
        );
    });
    return @removed;
}


sub randomize_seeds {
    my $self = shift;
    $self->encryption_iv(random_bytes(16));
    $self->inner_random_stream_key(random_bytes(64));
    $self->master_seed(random_bytes(32));
    $self->stream_start_bytes(random_bytes(32));
    $self->transform_seed(random_bytes(32));
}

##############################################################################


sub key {
    my $self = shift;
    $KEYS{$self} = File::KDBX::Key->new(@_) if @_;
    $KEYS{$self};
}


sub composite_key {
    my $self = shift;
    require File::KDBX::Key::Composite;
    return File::KDBX::Key::Composite->new(@_);
}


sub kdf {
    my $self = shift;
    my %args = @_ % 2 == 1 ? (params => shift, @_) : @_;

    my $params = $args{params};
    my $compat = $args{compatible} // 1;

    $params //= $self->kdf_parameters;
    $params = {%{$params || {}}};

    if (empty $params || !defined $params->{+KDF_PARAM_UUID}) {
        $params->{+KDF_PARAM_UUID} = KDF_UUID_AES;
    }
    if ($params->{+KDF_PARAM_UUID} eq KDF_UUID_AES) {
        # AES_CHALLENGE_RESPONSE is equivalent to AES if there are no challenge-response keys, and since
        # non-KeePassXC implementations don't support challenge-response keys anyway, there's no problem with
        # always using AES_CHALLENGE_RESPONSE for all KDBX4+ databases.
        # For compatibility, we should not *write* AES_CHALLENGE_RESPONSE, but the dumper handles that.
        if ($self->version >= KDBX_VERSION_4_0) {
            $params->{+KDF_PARAM_UUID} = KDF_UUID_AES_CHALLENGE_RESPONSE;
        }
        $params->{+KDF_PARAM_AES_SEED}   //= $self->transform_seed;
        $params->{+KDF_PARAM_AES_ROUNDS} //= $self->transform_rounds;
    }

    require File::KDBX::KDF;
    return File::KDBX::KDF->new(%$params);
}

sub transform_seed {
    my $self = shift;
    $self->headers->{+HEADER_TRANSFORM_SEED} =
        $self->headers->{+HEADER_KDF_PARAMETERS}{+KDF_PARAM_AES_SEED} = shift if @_;
    $self->headers->{+HEADER_TRANSFORM_SEED} =
        $self->headers->{+HEADER_KDF_PARAMETERS}{+KDF_PARAM_AES_SEED} //= random_bytes(32);
}

sub transform_rounds {
    my $self = shift;
    $self->headers->{+HEADER_TRANSFORM_ROUNDS} =
        $self->headers->{+HEADER_KDF_PARAMETERS}{+KDF_PARAM_AES_ROUNDS} = shift if @_;
    $self->headers->{+HEADER_TRANSFORM_ROUNDS} =
        $self->headers->{+HEADER_KDF_PARAMETERS}{+KDF_PARAM_AES_ROUNDS} //= 100_000;
}


sub cipher {
    my $self = shift;
    my %args = @_;

    $args{uuid} //= $self->headers->{+HEADER_CIPHER_ID};
    $args{iv}   //= $self->headers->{+HEADER_ENCRYPTION_IV};

    require File::KDBX::Cipher;
    return File::KDBX::Cipher->new(%args);
}


sub random_stream {
    my $self = shift;
    my %args = @_;

    $args{stream_id} //= delete $args{id} // $self->inner_random_stream_id;
    $args{key} //= $self->inner_random_stream_key;

    require File::KDBX::Cipher;
    File::KDBX::Cipher->new(%args);
}

sub inner_random_stream_id {
    my $self = shift;
    $self->inner_headers->{+INNER_HEADER_INNER_RANDOM_STREAM_ID}
        = $self->headers->{+HEADER_INNER_RANDOM_STREAM_ID} = shift if @_;
    $self->inner_headers->{+INNER_HEADER_INNER_RANDOM_STREAM_ID}
        //= $self->headers->{+HEADER_INNER_RANDOM_STREAM_ID} //= do {
        my $version = $self->minimum_version;
        $version < KDBX_VERSION_4_0 ? STREAM_ID_SALSA20 : STREAM_ID_CHACHA20;
    };
}

sub inner_random_stream_key {
    my $self = shift;
    if (@_) {
        # These are probably the same SvPV so erasing one will CoW, but erasing the second should do the
        # trick anyway.
        erase \$self->inner_headers->{+INNER_HEADER_INNER_RANDOM_STREAM_KEY};
        erase \$self->headers->{+HEADER_INNER_RANDOM_STREAM_KEY};
        $self->inner_headers->{+INNER_HEADER_INNER_RANDOM_STREAM_KEY}
            = $self->headers->{+HEADER_INNER_RANDOM_STREAM_KEY} = shift;
    }
    $self->inner_headers->{+INNER_HEADER_INNER_RANDOM_STREAM_KEY}
        //= $self->headers->{+HEADER_INNER_RANDOM_STREAM_KEY} //= random_bytes(64); # 32
}

#########################################################################################

sub _handle_signal {
    my $self    = shift;
    my $object  = shift;
    my $type    = shift;

    my %handlers = (
        'entry.added'           => \&_handle_object_added,
        'group.added'           => \&_handle_object_added,
        'entry.removed'         => \&_handle_object_removed,
        'group.removed'         => \&_handle_object_removed,
        'entry.uuid.changed'    => \&_handle_entry_uuid_changed,
        'group.uuid.changed'    => \&_handle_group_uuid_changed,
    );
    my $handler = $handlers{$type} or return;
    $self->$handler($object, @_);
}

sub _handle_object_added {
    my $self    = shift;
    my $object  = shift;
    $self->remove_deleted_object($object->uuid);
}

sub _handle_object_removed {
    my $self        = shift;
    my $object      = shift;
    my $old_uuid    = $object->{uuid} // return;

    my $meta = $self->meta;
    $self->recycle_bin_uuid(UUID_NULL)          if $old_uuid eq ($meta->{recycle_bin_uuid} // '');
    $self->entry_templates_group(UUID_NULL)     if $old_uuid eq ($meta->{entry_templates_group} // '');
    $self->last_selected_group(UUID_NULL)       if $old_uuid eq ($meta->{last_selected_group} // '');
    $self->last_top_visible_group(UUID_NULL)    if $old_uuid eq ($meta->{last_top_visible_group} // '');

    $self->add_deleted_object($old_uuid);
}

sub _handle_entry_uuid_changed {
    my $self        = shift;
    my $object      = shift;
    my $new_uuid    = shift;
    my $old_uuid    = shift // return;

    my $old_pretty = format_uuid($old_uuid);
    my $new_pretty = format_uuid($new_uuid);
    my $fieldref_match = qr/\{REF:([TUPANI])\@I:\Q$old_pretty\E\}/is;

    $self->entries->each(sub {
        $_->previous_parent_group($new_uuid) if $old_uuid eq ($_->{previous_parent_group} // '');

        for my $string (values %{$_->strings}) {
            next if !defined $string->{value} || $string->{value} !~ $fieldref_match;
            my $txn = $_->begin_work;
            $string->{value} =~ s/$fieldref_match/{REF:$1\@I:$new_pretty}/g;
            $txn->commit;
        }
    });
}

sub _handle_group_uuid_changed {
    my $self        = shift;
    my $object      = shift;
    my $new_uuid    = shift;
    my $old_uuid    = shift // return;

    my $meta = $self->meta;
    $self->recycle_bin_uuid($new_uuid)          if $old_uuid eq ($meta->{recycle_bin_uuid} // '');
    $self->entry_templates_group($new_uuid)     if $old_uuid eq ($meta->{entry_templates_group} // '');
    $self->last_selected_group($new_uuid)       if $old_uuid eq ($meta->{last_selected_group} // '');
    $self->last_top_visible_group($new_uuid)    if $old_uuid eq ($meta->{last_top_visible_group} // '');

    $self->groups->each(sub {
        $_->last_top_visible_entry($new_uuid)   if $old_uuid eq ($_->{last_top_visible_entry} // '');
        $_->previous_parent_group($new_uuid)    if $old_uuid eq ($_->{previous_parent_group} // '');
    });
    $self->entries->each(sub {
        $_->previous_parent_group($new_uuid)    if $old_uuid eq ($_->{previous_parent_group} // '');
    });
}

#########################################################################################


#########################################################################################

sub TO_JSON { +{%{$_[0]}} }

1;

__END__

=pod

=encoding UTF-8

=for markdown [![Linux](https://github.com/chazmcgarvey/File-KDBX/actions/workflows/linux.yml/badge.svg)](https://github.com/chazmcgarvey/File-KDBX/actions/workflows/linux.yml)
[![macOS](https://github.com/chazmcgarvey/File-KDBX/actions/workflows/macos.yml/badge.svg)](https://github.com/chazmcgarvey/File-KDBX/actions/workflows/macos.yml)
[![Windows](https://github.com/chazmcgarvey/File-KDBX/actions/workflows/windows.yml/badge.svg)](https://github.com/chazmcgarvey/File-KDBX/actions/workflows/windows.yml)

=for HTML <a title="Linux" href="https://github.com/chazmcgarvey/File-KDBX/actions/workflows/linux.yml"><img src="https://github.com/chazmcgarvey/File-KDBX/actions/workflows/linux.yml/badge.svg"></a>
<a title="macOS" href="https://github.com/chazmcgarvey/File-KDBX/actions/workflows/macos.yml"><img src="https://github.com/chazmcgarvey/File-KDBX/actions/workflows/macos.yml/badge.svg"></a>
<a title="Windows" href="https://github.com/chazmcgarvey/File-KDBX/actions/workflows/windows.yml"><img src="https://github.com/chazmcgarvey/File-KDBX/actions/workflows/windows.yml/badge.svg"></a>

=head1 NAME

File::KDBX - Encrypted database to store secret text and files

=head1 VERSION

version 0.904

=head1 SYNOPSIS

    use File::KDBX;

    # Create a new database from scratch
    my $kdbx = File::KDBX->new;

    # Add some objects to the database
    my $group = $kdbx->add_group(
        name => 'Passwords',
    );
    my $entry = $group->add_entry(
        title    => 'My Bank',
        username => 'mreynolds',
        password => 's3cr3t',
    );

    # Save the database to the filesystem
    $kdbx->dump_file('passwords.kdbx', 'masterpw changeme');

    # Load the database from the filesystem into a new database instance
    my $kdbx2 = File::KDBX->load_file('passwords.kdbx', 'masterpw changeme');

    # Iterate over database entries, print entry titles
    $kdbx2->entries->each(sub($entry, @) {
        say 'Entry: ', $entry->title;
    });

See L</RECIPES> for more examples.

=head1 DESCRIPTION

B<File::KDBX> provides everything you need to work with KDBX databases. A KDBX database is a hierarchical
object database which is commonly used to store secret information securely. It was developed for the KeePass
password safe. See L</"Introduction to KDBX"> for more information about KDBX.

This module lets you query entries, create new entries, delete entries, modify entries and more. The
distribution also includes various parsers and generators for serializing and persisting databases.

The design of this software was influenced by the L<KeePassXC|https://github.com/keepassxreboot/keepassxc>
implementation of KeePass as well as the L<File::KeePass> module. B<File::KeePass> is an alternative module
that works well in most cases but has a small backlog of bugs and security issues and also does not work with
newer KDBX version 4 files. If you're coming here from the B<File::KeePass> world, you might be interested in
L<File::KeePass::KDBX> that is a drop-in replacement for B<File::KeePass> that uses B<File::KDBX> for storage.

This software is a B<pre-1.0 release>. The interface should be considered pretty stable, but there might be
minor changes up until a 1.0 release. Breaking changes will be noted in the F<Changes> file.

=head2 Features

=over 4

=item *

☑ Read and write KDBX version 3 - version 4.1

=item *

☑ Read and write KDB files (requires L<File::KeePass>)

=item *

☑ Unicode character strings

=item *

☑ L</"Simple Expression"> Searching

=item *

☑ L<Placeholders|File::KDBX::Entry/Placeholders> and L<field references|/resolve_reference>

=item *

☑ L<One-time passwords|File::KDBX::Entry/"One-time Passwords">

=item *

☑ L<Very secure|/SECURITY>

=item *

☑ L</"Memory Protection">

=item *

☑ Challenge-response key components, like L<YubiKey|File::KDBX::Key::YubiKey>

=item *

☑ Variety of L<key file|File::KDBX::Key::File> types: binary, hexed, hashed, XML v1 and v2

=item *

☑ Pluggable registration of different kinds of ciphers and key derivation functions

=item *

☑ Built-in database maintenance functions

=item *

☑ Pretty fast, with L<XS optimizations|File::KDBX::XS> available

=item *

☒ Database synchronization / merging (not yet)

=back

=head2 Introduction to KDBX

A KDBX database consists of a tree of I<groups> and I<entries>, with a single I<root> group. Entries can
contain zero or more key-value pairs of I<strings> and zero or more I<binaries> (i.e. octet strings). Groups,
entries, strings and binaries: that's the KDBX vernacular. A small amount of metadata (timestamps, etc.) is
associated with each entry, group and the database as a whole.

You can think of a KDBX database kind of like a file system, where groups are directories, entries are files,
and strings and binaries make up a file's contents.

Databases are typically persisted as encrypted, compressed files. They are usually accessed directly (i.e.
not over a network). The primary focus of this type of database is data security. It is ideal for storing
relatively small amounts of data (strings and binaries) that must remain secret except to such individuals as
have the correct I<master key>. Even if the database file were to be "leaked" to the public Internet, it
should be virtually impossible to crack with a strong key. The KDBX format is most often used by password
managers to store passwords so that users can know a single strong password and not have to reuse passwords
across different websites. See L</SECURITY> for an overview of security considerations.

=head1 ATTRIBUTES

=head2 sig1

=head2 sig2

=head2 version

=head2 headers

=head2 inner_headers

=head2 meta

=head2 binaries

=head2 deleted_objects

Hash of UUIDs for objects that have been deleted. This includes groups, entries and even custom icons.

=head2 raw

Bytes contained within the encrypted layer of a KDBX file. This is only set when using
L<File::KDBX::Loader::Raw>.

=head2 comment

A text string associated with the database. Often unset.

=head2 cipher_id

The UUID of a cipher used to encrypt the database when stored as a file.

See L<File::KDBX::Cipher>.

=head2 compression_flags

Configuration for whether or not and how the database gets compressed. See
L<File::KDBX::Constants/":compression">.

=head2 master_seed

The master seed is a string of 32 random bytes that is used as salt in hashing the master key when loading
and saving the database. If a challenge-response key is used in the master key, the master seed is also the
challenge.

The master seed I<should> be changed each time the database is saved to file.

=head2 transform_seed

The transform seed is a string of 32 random bytes that is used in the key derivation function, either as the
salt or the key (depending on the algorithm).

The transform seed I<should> be changed each time the database is saved to file.

=head2 transform_rounds

The number of rounds or iterations used in the key derivation function. Increasing this number makes loading
and saving the database slower by design in order to make dictionary and brute force attacks more costly.

=head2 encryption_iv

The initialization vector used by the cipher.

The encryption IV I<should> be changed each time the database is saved to file.

=head2 inner_random_stream_key

The encryption key (possibly including the IV, depending on the cipher) used to encrypt the protected strings
within the database.

=head2 stream_start_bytes

A string of 32 random bytes written in the header and encrypted in the body. If the bytes do not match when
loading a file then the wrong master key was used or the file is corrupt. Only KDBX 2 and KDBX 3 files use
this. KDBX 4 files use an improved HMAC method to verify the master key and data integrity of the header and
entire file body.

=head2 inner_random_stream_id

A number indicating the cipher algorithm used to encrypt the protected strings within the database, usually
Salsa20 or ChaCha20. See L<File::KDBX::Constants/":random_stream">.

=head2 kdf_parameters

A hash/dict of key-value pairs used to configure the key derivation function. This is the KDBX4+ way to
configure the KDF, superceding L</transform_seed> and L</transform_rounds>.

=head2 generator

The name of the software used to generate the KDBX file.

=head2 header_hash

The header hash used to verify that the file header is not corrupt. (KDBX 2 - KDBX 3.1, removed KDBX 4.0)

=head2 database_name

Name of the database.

=head2 database_name_changed

Timestamp indicating when the database name was last changed.

=head2 database_description

Description of the database

=head2 database_description_changed

Timestamp indicating when the database description was last changed.

=head2 default_username

When a new entry is created, the I<UserName> string will be populated with this value.

=head2 default_username_changed

Timestamp indicating when the default username was last changed.

=head2 color

A color associated with the database (in the form C<#ffffff> where "f" is a hexidecimal digit). Some agents
use this to help users visually distinguish between different databases.

=head2 master_key_changed

Timestamp indicating when the master key was last changed.

=head2 master_key_change_rec

Number of days until the agent should prompt to recommend changing the master key.

=head2 master_key_change_force

Number of days until the agent should prompt to force changing the master key.

Note: This is purely advisory. It is up to the individual agent software to actually enforce it.
B<File::KDBX> does NOT enforce it.

=head2 custom_icons

Array of custom icons that can be associated with groups and entries.

This list can be managed with the methods L</add_custom_icon> and L</remove_custom_icon>.

=head2 recycle_bin_enabled

Boolean indicating whether removed groups and entries should go to a recycle bin or be immediately deleted.

=head2 recycle_bin_uuid

The UUID of a group used to store thrown-away groups and entries.

=head2 recycle_bin_changed

Timestamp indicating when the recycle bin group was last changed.

=head2 entry_templates_group

The UUID of a group containing template entries used when creating new entries.

=head2 entry_templates_group_changed

Timestamp indicating when the entry templates group was last changed.

=head2 last_selected_group

The UUID of the previously-selected group.

=head2 last_top_visible_group

The UUID of the group visible at the top of the list.

=head2 history_max_items

The maximum number of historical entries that should be kept for each entry. Default is 10.

=head2 history_max_size

The maximum total size (in bytes) that each individual entry's history is allowed to grow. Default is 6 MiB.

=head2 maintenance_history_days

The maximum age (in days) historical entries should be kept. Default it 365.

=head2 settings_changed

Timestamp indicating when the database settings were last updated.

=head2 protect_title

Alias of the L</memory_protection> setting for the I<Title> string.

=head2 protect_username

Alias of the L</memory_protection> setting for the I<UserName> string.

=head2 protect_password

Alias of the L</memory_protection> setting for the I<Password> string.

=head2 protect_url

Alias of the L</memory_protection> setting for the I<URL> string.

=head2 protect_notes

Alias of the L</memory_protection> setting for the I<Notes> string.

=head1 METHODS

=head2 new

    $kdbx = File::KDBX->new(%attributes);
    $kdbx = File::KDBX->new($kdbx); # copy constructor

Construct a new L<File::KDBX>.

=head2 init

    $kdbx = $kdbx->init(%attributes);

Initialize a L<File::KDBX> with a set of attributes. Returns itself to allow method chaining.

This is called by L</new>.

=head2 reset

    $kdbx = $kdbx->reset;

Set a L<File::KDBX> to an empty state, ready to load a KDBX file or build a new one. Returns itself to allow
method chaining.

=head2 clone

    $kdbx_copy = $kdbx->clone;
    $kdbx_copy = File::KDBX->new($kdbx);

Clone a L<File::KDBX>. The clone will be an exact copy and completely independent of the original.

=head2 load

=head2 load_string

=head2 load_file

=head2 load_handle

    $kdbx = KDBX::File->load(\$string, $key);
    $kdbx = KDBX::File->load(*IO, $key);
    $kdbx = KDBX::File->load($filepath, $key);
    $kdbx->load(...);           # also instance method

    $kdbx = File::KDBX->load_string($string, $key);
    $kdbx = File::KDBX->load_string(\$string, $key);
    $kdbx->load_string(...);    # also instance method

    $kdbx = File::KDBX->load_file($filepath, $key);
    $kdbx->load_file(...);      # also instance method

    $kdbx = File::KDBX->load_handle($fh, $key);
    $kdbx = File::KDBX->load_handle(*IO, $key);
    $kdbx->load_handle(...);    # also instance method

Load a KDBX file from a string buffer, IO handle or file from a filesystem.

L<File::KDBX::Loader> does the heavy lifting.

=head2 dump

=head2 dump_string

=head2 dump_file

=head2 dump_handle

    $kdbx->dump(\$string, $key);
    $kdbx->dump(*IO, $key);
    $kdbx->dump($filepath, $key);

    $kdbx->dump_string(\$string, $key);
    \$string = $kdbx->dump_string($key);

    $kdbx->dump_file($filepath, $key);

    $kdbx->dump_handle($fh, $key);
    $kdbx->dump_handle(*IO, $key);

Dump a KDBX file to a string buffer, IO handle or file in a filesystem.

L<File::KDBX::Dumper> does the heavy lifting.

=head2 user_agent_string

    $string = $kdbx->user_agent_string;

Get a text string identifying the database client software.

=head2 memory_protection

    \%settings = $kdbx->memory_protection
    $kdbx->memory_protection(\%settings);

    $bool = $kdbx->memory_protection($string_key);
    $kdbx->memory_protection($string_key => $bool);

Get or set memory protection settings. This globally (for the whole database) configures whether and which of
the standard strings should be memory-protected. The default setting is to memory-protect only I<Password>
strings.

Memory protection can be toggled individually for each entry string, and individual settings take precedence
over these global settings.

=head2 minimum_version

    $version = $kdbx->minimum_version;

Determine the minimum file version required to save a database losslessly. Using certain databases features
might increase this value. For example, setting the KDF to Argon2 will increase the minimum version to at
least C<KDBX_VERSION_4_0> (i.e. C<0x00040000>) because Argon2 was introduced with KDBX4.

This method never returns less than C<KDBX_VERSION_3_1> (i.e. C<0x00030001>). That file version is so
ubiquitous and well-supported, there are seldom reasons to dump in a lesser format nowadays.

B<WARNING:> If you dump a database with a minimum version higher than the current L</version>, the dumper will
typically issue a warning and automatically upgrade the database. This seems like the safest behavior in order
to avoid data loss, but lower versions have the benefit of being compatible with more software. It is possible
to prevent auto-upgrades by explicitly telling the dumper which version to use, but you do run the risk of
data loss. A database will never be automatically downgraded.

=head2 root

    $group = $kdbx->root;
    $kdbx->root($group);

Get or set a database's root group. You don't necessarily need to explicitly create or set a root group
because it autovivifies when adding entries and groups to the database.

Every database has only a single root group at a time. Some old KDB files might have multiple root groups.
When reading such files, a single implicit root group is created to contain the actual root groups. When
writing to such a format, if the root group looks like it was implicitly created then it won't be written and
the resulting file might have multiple root groups, as it was before loading. This allows working with older
files without changing their written internal structure while still adhering to modern semantics while the
database is opened.

The root group of a KDBX database contains all of the database's entries and other groups. If you replace the
root group, you are essentially replacing the entire database contents with something else.

=head2 trace_lineage

    \@lineage = $kdbx->trace_lineage($group);
    \@lineage = $kdbx->trace_lineage($group, $base_group);
    \@lineage = $kdbx->trace_lineage($entry);
    \@lineage = $kdbx->trace_lineage($entry, $base_group);

Get the direct line of ancestors from C<$base_group> (default: the root group) to a group or entry. The
lineage includes the base group but I<not> the target group or entry. Returns C<undef> if the target is not in
the database structure.

=head2 recycle_bin

    $group = $kdbx->recycle_bin;
    $kdbx->recycle_bin($group);

Get or set the recycle bin group. Returns C<undef> if there is no recycle bin and L</recycle_bin_enabled> is
false, otherwise the current recycle bin or an autovivified recycle bin group is returned.

=head2 entry_templates

    $group = $kdbx->entry_templates;
    $kdbx->entry_templates($group);

Get or set the entry templates group. May return C<undef> if unset.

=head2 last_selected

    $group = $kdbx->last_selected;
    $kdbx->last_selected($group);

Get or set the last selected group. May return C<undef> if unset.

=head2 last_top_visible

    $group = $kdbx->last_top_visible;
    $kdbx->last_top_visible($group);

Get or set the last top visible group. May return C<undef> if unset.

=head2 add_group

    $kdbx->add_group($group);
    $kdbx->add_group(%group_attributes, %options);

Add a group to a database. This is equivalent to identifying a parent group and calling
L<File::KDBX::Group/add_group> on the parent group, forwarding the arguments. Available options:

=over 4

=item *

C<group> - Group object or group UUID to add the group to (default: root group)

=back

=head2 groups

    \&iterator = $kdbx->groups(%options);
    \&iterator = $kdbx->groups($base_group, %options);

Get an L<File::KDBX::Iterator> over I<groups> within a database. Options:

=over 4

=item *

C<base> - Only include groups within a base group (same as C<$base_group>) (default: L</root>)

=item *

C<inclusive> - Include the base group in the results (default: true)

=item *

C<algorithm> - Search algorithm, one of C<ids>, C<bfs> or C<dfs> (default: C<ids>)

=back

=head2 add_entry

    $kdbx->add_entry($entry, %options);
    $kdbx->add_entry(%entry_attributes, %options);

Add a entry to a database. This is equivalent to identifying a parent group and calling
L<File::KDBX::Group/add_entry> on the parent group, forwarding the arguments. Available options:

=over 4

=item *

C<group> - Group object or group UUID to add the entry to (default: root group)

=back

=head2 entries

    \&iterator = $kdbx->entries(%options);
    \&iterator = $kdbx->entries($base_group, %options);

Get an L<File::KDBX::Iterator> over I<entries> within a database. Supports the same options as L</groups>,
plus some new ones:

=over 4

=item *

C<auto_type> - Only include entries with auto-type enabled (default: false, include all)

=item *

C<searching> - Only include entries within groups with searching enabled (default: false, include all)

=item *

C<history> - Also include historical entries (default: false, include only current entries)

=back

=head2 objects

    \&iterator = $kdbx->objects(%options);
    \&iterator = $kdbx->objects($base_group, %options);

Get an L<File::KDBX::Iterator> over I<objects> within a database. Groups and entries are considered objects,
so this is essentially a combination of L</groups> and L</entries>. This won't often be useful, but it can be
convenient for maintenance tasks. This method takes the same options as L</groups> and L</entries>.

=head2 custom_icon

    \%icon = $kdbx->custom_icon($uuid);
    $kdbx->custom_icon($uuid => \%icon);
    $kdbx->custom_icon(%icon);
    $kdbx->custom_icon(uuid => $value, %icon);

Get or set custom icons.

=head2 custom_icon_data

    $image_data = $kdbx->custom_icon_data($uuid);

Get a custom icon image data.

=head2 add_custom_icon

    $uuid = $kdbx->add_custom_icon($image_data, %attributes);
    $uuid = $kdbx->add_custom_icon(%attributes);

Add a custom icon and get its UUID. If not provided, a random UUID will be generated. Possible attributes:

=over 4

=item *

C<uuid> - Icon UUID (default: autogenerated)

=item *

C<data> - Image data (same as C<$image_data>)

=item *

C<name> - Name of the icon (text, KDBX4.1+)

=item *

C<last_modification_time> - Just what it says (datetime, KDBX4.1+)

=back

=head2 remove_custom_icon

    $kdbx->remove_custom_icon($uuid);

Remove a custom icon.

=head2 custom_data

    \%all_data = $kdbx->custom_data;
    $kdbx->custom_data(\%all_data);

    \%data = $kdbx->custom_data($key);
    $kdbx->custom_data($key => \%data);
    $kdbx->custom_data(%data);
    $kdbx->custom_data(key => $value, %data);

Get and set custom data. Custom data is metadata associated with a database.

Each data item can have a few attributes associated with it.

=over 4

=item *

C<key> - A unique text string identifier used to look up the data item (required)

=item *

C<value> - A text string value (required)

=item *

C<last_modification_time> (optional, KDBX4.1+)

=back

=head2 custom_data_value

    $value = $kdbx->custom_data_value($key);

Exactly the same as L</custom_data> except returns just the custom data's value rather than a structure of
attributes. This is a shortcut for:

    my $data = $kdbx->custom_data($key);
    my $value = defined $data ? $data->{value} : undef;

=head2 public_custom_data

    \%all_data = $kdbx->public_custom_data;
    $kdbx->public_custom_data(\%all_data);

    $value = $kdbx->public_custom_data($key);
    $kdbx->public_custom_data($key => $value);

Get and set public custom data. Public custom data is similar to custom data but different in some important
ways. Public custom data:

=over 4

=item *

can store strings, booleans and up to 64-bit integer values (custom data can only store text values)

=item *

is NOT encrypted within a KDBX file (hence the "public" part of the name)

=item *

is a plain hash/dict of key-value pairs with no other associated fields (like modification times)

=back

=head2 add_deleted_object

    $kdbx->add_deleted_object($uuid);

Add a UUID to the deleted objects list. This list is used to support automatic database merging.

You typically do not need to call this yourself because the list will be populated automatically as objects
are removed.

=head2 remove_deleted_object

    $kdbx->remove_deleted_object($uuid);

Remove a UUID from the deleted objects list. This list is used to support automatic database merging.

You typically do not need to call this yourself because the list will be maintained automatically as objects
are added.

=head2 clear_deleted_objects

Remove all UUIDs from the deleted objects list.  This list is used to support automatic database merging, but
if you don't need merging then you can clear deleted objects to reduce the database file size.

=head2 resolve_reference

    $string = $kdbx->resolve_reference($reference);
    $string = $kdbx->resolve_reference($wanted, $search_in, $expression);

Resolve a L<field reference|https://keepass.info/help/base/fieldrefs.html>. A field reference is a kind of
string placeholder. You can use a field reference to refer directly to a standard field within an entry. Field
references are resolved automatically while expanding entry strings (i.e. replacing placeholders), but you can
use this method to resolve on-the-fly references that aren't part of any actual string in the database.

If the reference does not resolve to any field, C<undef> is returned. If the reference resolves to multiple
fields, only the first one is returned (in the same order as iterated by L</entries>). To avoid ambiguity, you
can refer to a specific entry by its UUID.

The syntax of a reference is: C<< {REF:<WantedField>@<SearchIn>:<Text>} >>. C<Text> is a
L</"Simple Expression">. C<WantedField> and C<SearchIn> are both single character codes representing a field:

=over 4

=item *

C<T> - Title

=item *

C<U> - UserName

=item *

C<P> - Password

=item *

C<A> - URL

=item *

C<N> - Notes

=item *

C<I> - UUID

=item *

C<O> - Other custom strings

=back

Since C<O> does not represent any specific field, it cannot be used as the C<WantedField>.

Examples:

To get the value of the I<UserName> string of the first entry with "My Bank" in the title:

    my $username = $kdbx->resolve_reference('{REF:U@T:"My Bank"}');
    # OR the {REF:...} wrapper is optional
    my $username = $kdbx->resolve_reference('U@T:"My Bank"');
    # OR separate the arguments
    my $username = $kdbx->resolve_reference(U => T => '"My Bank"');

Note how the text is a L</"Simple Expression">, so search terms with spaces must be surrounded in double
quotes.

To get the I<Password> string of a specific entry (identified by its UUID):

    my $password = $kdbx->resolve_reference('{REF:P@I:46C9B1FFBD4ABC4BBB260C6190BAD20C}');

=head2 lock

    $kdbx->lock;

Encrypt all protected strings and binaries in a database. The encrypted data is stored in
a L<File::KDBX::Safe> associated with the database and the actual values will be replaced with C<undef> to
indicate their protected state. Returns itself to allow method chaining.

You can call C<lock> on an already-locked database to memory-protect any unprotected strings and binaries
added after the last time the database was locked.

=head2 unlock

    $kdbx->unlock;

Decrypt all protected strings and binaries in a database, replacing C<undef> value placeholders with their
actual, unprotected values. Returns itself to allow method chaining.

=head2 unlock_scoped

    $guard = $kdbx->unlock_scoped;

Unlock a database temporarily, relocking when the guard is released (typically at the end of a scope). Returns
C<undef> if the database is already unlocked.

See L</lock> and L</unlock>.

Example:

    {
        my $guard = $kdbx->unlock_scoped;
        ...;
    }
    # $kdbx is now memory-locked

=head2 peek

    $string = $kdbx->peek(\%string);
    $string = $kdbx->peek(\%binary);

Peek at the value of a protected string or binary without unlocking the whole database. The argument can be
a string or binary hashref as returned by L<File::KDBX::Entry/string> or L<File::KDBX::Entry/binary>.

=head2 is_locked

    $bool = $kdbx->is_locked;

Get whether or not a database's contents are in a locked (i.e. memory-protected) state. If this is true, then
some or all of the protected strings and binaries within the database will be unavailable (literally have
C<undef> values) until L</unlock> is called.

=head2 remove_empty_groups

    $kdbx->remove_empty_groups;

Remove groups with no subgroups and no entries.

=head2 remove_unused_icons

    $kdbx->remove_unused_icons;

Remove icons that are not associated with any entry or group in the database.

=head2 remove_duplicate_icons

    $kdbx->remove_duplicate_icons;

Remove duplicate icons as determined by hashing the icon data.

=head2 prune_history

    $kdbx->prune_history(%options);

Remove just as many older historical entries as necessary to get under certain limits.

=over 4

=item *

C<max_items> - Maximum number of historical entries to keep (default: value of L</history_max_items>, no limit: -1)

=item *

C<max_size> - Maximum total size (in bytes) of historical entries to keep (default: value of L</history_max_size>, no limit: -1)

=item *

C<max_age> - Maximum age (in days) of historical entries to keep (default: 365, no limit: -1)

=back

=head2 randomize_seeds

    $kdbx->randomize_seeds;

Set various keys, seeds and IVs to random values. These values are used by the cryptographic functions that
secure the database when dumped. The attributes that will be randomized are:

=over 4

=item *

L</encryption_iv>

=item *

L</inner_random_stream_key>

=item *

L</master_seed>

=item *

L</stream_start_bytes>

=item *

L</transform_seed>

=back

Randomizing these values has no effect on a loaded database. These are only used when a database is dumped.
You normally do not need to call this method explicitly because the dumper does it explicitly by default.

=head2 key

    $key = $kdbx->key;
    $key = $kdbx->key($key);
    $key = $kdbx->key($primitive);

Get or set a L<File::KDBX::Key>. This is the master key (e.g. a password or a key file that can decrypt
a database). You can also pass a primitive castable to a B<Key>. See L<File::KDBX::Key/new> for an explanation
of what the primitive can be.

You generally don't need to call this directly because you can provide the key directly to the loader or
dumper when loading or dumping a KDBX file.

=head2 composite_key

    $key = $kdbx->composite_key($key);
    $key = $kdbx->composite_key($primitive);

Construct a L<File::KDBX::Key::Composite> from a B<Key> or primitive. See L<File::KDBX::Key/new> for an
explanation of what the primitive can be. If the primitive does not represent a composite key, it will be
wrapped.

You generally don't need to call this directly. The loader and dumper use it to transform a master key into
a raw encryption key.

=head2 kdf

    $kdf = $kdbx->kdf(%options);
    $kdf = $kdbx->kdf(\%parameters, %options);

Get a L<File::KDBX::KDF> (key derivation function).

Options:

=over 4

=item *

C<params> - KDF parameters, same as C<\%parameters> (default: value of L</kdf_parameters>)

=back

=head2 cipher

    $cipher = $kdbx->cipher(key => $key);
    $cipher = $kdbx->cipher(key => $key, iv => $iv, uuid => $uuid);

Get a L<File::KDBX::Cipher> capable of encrypting and decrypting the body of a database file.

A key is required. This should be a raw encryption key made up of a fixed number of octets (depending on the
cipher), not a L<File::KDBX::Key> or primitive.

If not passed, the UUID comes from C<< $kdbx->headers->{cipher_id} >> and the encryption IV comes from
C<< $kdbx->headers->{encryption_iv} >>.

You generally don't need to call this directly. The loader and dumper use it to decrypt and encrypt KDBX
files.

=head2 random_stream

    $cipher = $kdbx->random_stream;
    $cipher = $kdbx->random_stream(id => $stream_id, key => $key);

Get a L<File::KDBX::Cipher::Stream> for decrypting and encrypting protected values.

If not passed, the ID and encryption key comes from C<< $kdbx->headers->{inner_random_stream_id} >> and
C<< $kdbx->headers->{inner_random_stream_key} >> (respectively) for KDBX3 files and from
C<< $kdbx->inner_headers->{inner_random_stream_key} >> and
C<< $kdbx->inner_headers->{inner_random_stream_id} >> (respectively) for KDBX4 files.

You generally don't need to call this directly. The loader and dumper use it to scramble protected strings.

=for Pod::Coverage STORABLE_freeze STORABLE_thaw TO_JSON

=head1 RECIPES

=head2 Create a new database

    my $kdbx = File::KDBX->new;

    my $group = $kdbx->add_group(name => 'Passwords);
    my $entry = $group->add_entry(
        title    => 'WayneCorp',
        username => 'bwayne',
        password => 'iambatman',
        url      => 'https://example.com/login'
    );
    $entry->add_auto_type_window_association('WayneCorp - Mozilla Firefox', '{PASSWORD}{ENTER}');

    $kdbx->dump_file('mypasswords.kdbx', 'master password CHANGEME');

=head2 Read an existing database

    my $kdbx = File::KDBX->load_file('mypasswords.kdbx', 'master password CHANGEME');
    $kdbx->unlock;  # cause $entry->password below to be defined

    $kdbx->entries->each(sub($entry, @) {
        say 'Found password for: ', $entry->title;
        say '  Username: ', $entry->username;
        say '  Password: ', $entry->password;
    });

=head2 Search for entries

    my @entries = $kdbx->entries(searching => 1)
        ->grep(title => 'WayneCorp')
        ->each;     # return all matches

The C<searching> option limits results to only entries within groups with searching enabled. Other options are
also available. See L</entries>.

See L</QUERY> for many more query examples.

=head2 Search for entries by auto-type window association

    my $window_title = 'WayneCorp - Mozilla Firefox';

    my $entries = $kdbx->entries(auto_type => 1)
        ->filter(sub {
            my ($ata) = grep { $_->{window} =~ /\Q$window_title\E/i } @{$_->auto_type_associations};
            return [$_, $ata->{keystroke_sequence}] if $ata;
        })
        ->each(sub {
            my ($entry, $keys) = @$_;
            say 'Entry title: ', $entry->title, ', key sequence: ', $keys;
        });

Example output:

    Entry title: WayneCorp, key sequence: {PASSWORD}{ENTER}

=head2 Remove entries from a database

    $kdbx->entries
        ->grep(notes => {'=~' => qr/too old/i})
        ->each(sub { $_->recycle });

Recycle all entries with the string "too old" appearing in the B<Notes> string.

=head2 Remove empty groups

    $kdbx->groups(algorithm => 'dfs')
        ->where(-true => 'is_empty')
        ->each('remove');

With the search/iteration C<algorithm> set to "dfs", groups will be ordered deepest first and the root group
will be last. This allows removing groups that only contain empty groups.

This can also be done with one call to L</remove_empty_groups>.

=head1 SECURITY

One of the biggest threats to your database security is how easily the encryption key can be brute-forced.
Strong brute-force protection depends on:

=over 4

=item *

Using unguessable passwords, passphrases and key files.

=item *

Using a brute-force resistent key derivation function.

=back

The first factor is up to you. This module does not enforce strong master keys. It is up to you to pick or
generate strong keys.

The KDBX format allows for the key derivation function to be tuned. The idea is that you want each single
brute-force attempt to be expensive (in terms of time, CPU usage or memory usage), so that making a lot of
attempts (which would be required if you have a strong master key) gets I<really> expensive.

How expensive you want to make each attempt is up to you and can depend on the application.

This and other KDBX-related security issues are covered here more in depth:
L<https://keepass.info/help/base/security.html>

Here are other security risks you should be thinking about:

=head2 Cryptography

This distribution uses the excellent L<CryptX> and L<Crypt::Argon2> packages to handle all crypto-related
functions. As such, a lot of the security depends on the quality of these dependencies. Fortunately these
modules are maintained and appear to have good track records.

The KDBX format has evolved over time to incorporate improved security practices and cryptographic functions.
This package uses the following functions for authentication, hashing, encryption and random number
generation:

=over 4

=item *

AES-128 (legacy)

=item *

AES-256

=item *

Argon2d & Argon2id

=item *

CBC block mode

=item *

HMAC-SHA256

=item *

SHA256

=item *

SHA512

=item *

Salsa20 & ChaCha20

=item *

Twofish

=back

At the time of this writing, I am not aware of any successful attacks against any of these functions. These
are among the most-analyzed and widely-adopted crypto functions available.

The KDBX format allows the body cipher and key derivation function to be configured. If a flaw is discovered
in one of these functions, you can hopefully just switch to a better function without needing to update this
software. A later software release may phase out the use of any functions which are no longer secure.

=head2 Memory Protection

It is not a good idea to keep secret information unencrypted in system memory for longer than is needed. The
address space of your program can generally be read by a user with elevated privileges on the system. If your
system is memory-constrained or goes into a hibernation mode, the contents of your address space could be
written to a disk where it might be persisted for long time.

There might be system-level things you can do to reduce your risk, like using swap encryption and limiting
system access to your program's address space while your program is running.

B<File::KDBX> helps minimize (but not eliminate) risk by keeping secrets encrypted in memory until accessed
and zeroing out memory that holds secrets after they're no longer needed, but it's not a silver bullet.

For one thing, the encryption key is stored in the same address space. If core is dumped, the encryption key
is available to be found out. But at least there is the chance that the encryption key and the encrypted
secrets won't both be paged out together while memory-constrained.

Another problem is that some perls (somewhat notoriously) copy around memory behind the scenes willy nilly,
and it's difficult know when perl makes a copy of a secret in order to be able to zero it out later. It might
be impossible. The good news is that perls with SvPV copy-on-write (enabled by default beginning with perl
5.20) are much better in this regard. With COW, it's mostly possible to know what operations will cause perl
to copy the memory of a scalar string, and the number of copies will be significantly reduced. There is a unit
test named F<t/memory-protection.t> in this distribution that can be run on POSIX systems to determine how
well B<File::KDBX> memory protection is working.

Memory protection also depends on how your application handles secrets. If your app code is handling scalar
strings with secret information, it's up to you to make sure its memory is zeroed out when no longer needed.
L<File::KDBX::Util/erase> et al. provide some tools to help accomplish this. Or if you're not too concerned
about the risks memory protection is meant to mitigate, then maybe don't worry about it. The security policy
of B<File::KDBX> is to try hard to keep secrets protected while in memory so that your app might claim a high
level of security, in case you care about that.

There are some memory protection strategies that B<File::KDBX> does NOT use today but could in the future:

Many systems allow programs to mark unswappable pages. Secret information should ideally be stored in such
pages. You could potentially use L<mlockall(2)> (or equivalent for your system) in your own application to
prevent the entire address space from being swapped.

Some systems provide special syscalls for storing secrets in memory while keeping the encryption key outside
of the program's address space, like C<CryptProtectMemory> for Windows. This could be a good option, though
unfortunately not portable.

=head1 QUERY

To find things in a KDBX database, you should use a filtered iterator. If you have an iterator, such as
returned by L</entries>, L</groups> or even L</objects> you can filter it using L<File::KDBX::Iterator/where>.

    my $filtered_entries = $kdbx->entries->where(\&query);

A C<\&query> is just a subroutine that you can either write yourself or have generated for you from either
a L</"Simple Expression"> or L</"Declarative Syntax">. It's easier to have your query generated, so I'll cover
that first.

=head2 Simple Expression

A simple expression is mostly compatible with the KeePass 2 implementation
L<described here|https://keepass.info/help/base/search.html#mode_se>.

An expression is a string with one or more space-separated terms. Terms with spaces can be enclosed in double
quotes. Terms are negated if they are prefixed with a minus sign. A record must match every term on at least
one of the given fields.

So a simple expression is something like what you might type into a search engine. You can generate a simple
expression query using L<File::KDBX::Util/simple_expression_query> or by passing the simple expression as
a B<scalar reference> to C<where>.

To search for all entries in a database with the word "canyon" appearing anywhere in the title:

    my $entries = $kdbx->entries->where(\'canyon', qw[title]);

Notice the first argument is a B<scalarref>. This disambiguates a simple expression from other types of
queries covered below.

As mentioned, a simple expression can have multiple terms. This simple expression query matches any entry that
has the words "red" B<and> "canyon" anywhere in the title:

    my $entries = $kdbx->entries->where(\'red canyon', qw[title]);

Each term in the simple expression must be found for an entry to match.

To search for entries with "red" in the title but B<not> "canyon", just prepend "canyon" with a minus sign:

    my $entries = $kdbx->entries->where(\'red -canyon', qw[title]);

To search over multiple fields simultaneously, just list them all. To search for entries with "grocery" (but
not "Foodland") in the title or notes:

    my $entries = $kdbx->entries->where(\'grocery -Foodland', qw[title notes]);

The default operator is a case-insensitive regexp match, which is fine for searching text loosely. You can use
just about any binary comparison operator that perl supports. To specify an operator, list it after the simple
expression. For example, to search for any entry that has been used at least five times:

    my $entries = $kdbx->entries->where(\5, '>=', qw[usage_count]);

It helps to read it right-to-left, like "usage_count is greater than or equal to 5".

If you find the disambiguating structures to be distracting or confusing, you can also use the
L<File::KDBX::Util/simple_expression_query> function as a more intuitive alternative. The following example is
equivalent to the previous:

    my $entries = $kdbx->entries->where(simple_expression_query(5, '>=', qw[usage_count]));

=head2 Declarative Syntax

Structuring a declarative query is similar to L<SQL::Abstract/"WHERE CLAUSES">, but you don't have to be
familiar with that module. Just learn by examples here.

To search for all entries in a database titled "My Bank":

    my $entries = $kdbx->entries->where({ title => 'My Bank' });

The query here is C<< { title => 'My Bank' } >>. A hashref can contain key-value pairs where the key is an
attribute of the thing being searched for (in this case an entry) and the value is what you want the thing's
attribute to be to consider it a match. In this case, the attribute we're using as our match criteria is
L<File::KDBX::Entry/title>, a text field. If an entry has its title attribute equal to "My Bank", it's
a match.

A hashref can contain multiple attributes. The search candidate will be a match if I<all> of the specified
attributes are equal to their respective values. For example, to search for all entries with a particular URL
B<AND> username:

    my $entries = $kdbx->entries->where({
        url      => 'https://example.com',
        username => 'neo',
    });

To search for entries matching I<any> criteria, just change the hashref to an arrayref. To search for entries
with a particular URL B<OR> username:

    my $entries = $kdbx->entries->where([ # <-- Notice the square bracket
        url      => 'https://example.com',
        username => 'neo',
    ]);

You can use different operators to test different types of attributes. The L<File::KDBX::Entry/icon_id>
attribute is a number, so we should use a number comparison operator. To find entries using the smartphone
icon:

    my $entries = $kdbx->entries->where({
        icon_id => { '==', ICON_SMARTPHONE },
    });

Note: L<File::KDBX::Constants/ICON_SMARTPHONE> is just a constant from L<File::KDBX::Constants>. It isn't
special to this example or to queries generally. We could have just used a literal number.

The important thing to notice here is how we wrapped the condition in another hashref with a single key-value
pair where the key is the name of an operator and the value is the thing to match against. The supported
operators are:

=over 4

=item *

C<eq> - String equal

=item *

C<ne> - String not equal

=item *

C<lt> - String less than

=item *

C<gt> - String greater than

=item *

C<le> - String less than or equal

=item *

C<ge> - String greater than or equal

=item *

C<==> - Number equal

=item *

C<!=> - Number not equal

=item *

C<< < >> - Number less than

=item *

C<< > >> - Number greater than

=item *

C<< <= >> - Number less than or equal

=item *

C<< >= >> - Number less than or equal

=item *

C<=~> - String match regular expression

=item *

C<!~> - String does not match regular expression

=item *

C<!> - Boolean false

=item *

C<!!> - Boolean true

=back

Other special operators:

=over 4

=item *

C<-true> - Boolean true

=item *

C<-false> - Boolean false

=item *

C<-not> - Boolean false (alias for C<-false>)

=item *

C<-defined> - Is defined

=item *

C<-undef> - Is not defined

=item *

C<-empty> - Is empty

=item *

C<-nonempty> - Is not empty

=item *

C<-or> - Logical or

=item *

C<-and> - Logical and

=back

Let's see another example using an explicit operator. To find all groups except one in particular (identified
by its L<File::KDBX::Group/uuid>), we can use the C<ne> (string not equal) operator:

    my $groups = $kdbx->groups->where(
        uuid => {
            'ne' => uuid('596f7520-6172-6520-7370-656369616c2e'),
        },
    );

Note: L<File::KDBX::Util/uuid> is a little utility function to convert a UUID in its pretty form into bytes.
This utility function isn't special to this example or to queries generally. It could have been written with
a literal such as C<"\x59\x6f\x75\x20\x61...">, but that's harder to read.

Notice we searched for groups this time. Finding groups works exactly the same as it does for entries.

Notice also that we didn't wrap the query in hashref curly-braces or arrayref square-braces. Those are
optional. By default it will only match ALL attributes (as if there were curly-braces).

Testing the truthiness of an attribute is a little bit different because it isn't a binary operation. To find
all entries with the password quality check disabled:

    my $entries = $kdbx->entries->where('!' => 'quality_check');

This time the string after the operator is the attribute name rather than a value to compare the attribute
against. To test that a boolean value is true, use the C<!!> operator (or C<-true> if C<!!> seems a little too
weird for your taste):

    my $entries = $kdbx->entries->where('!!'  => 'quality_check');
    my $entries = $kdbx->entries->where(-true => 'quality_check');  # same thing

Yes, there is also a C<-false> and a C<-not> if you prefer one of those over C<!>. C<-false> and C<-not>
(along with C<-true>) are also special in that you can use them to invert the logic of a subquery. These are
logically equivalent:

    my $entries = $kdbx->entries->where(-not => { title => 'My Bank' });
    my $entries = $kdbx->entries->where(title => { 'ne' => 'My Bank' });

These special operators become more useful when combined with two more special operators: C<-and> and C<-or>.
With these, it is possible to construct more interesting queries with groups of logic. For example:

    my $entries = $kdbx->entries->where({
        title   => { '=~', qr/bank/ },
        -not    => {
            -or     => {
                notes   => { '=~', qr/business/ },
                icon_id => { '==', ICON_TRASHCAN_FULL },
            },
        },
    });

In English, find entries where the word "bank" appears anywhere in the title but also do not have either the
word "business" in the notes or are using the full trashcan icon.

=head2 Subroutine Query

Lastly, as mentioned at the top, you can ignore all this and write your own subroutine. Your subroutine will
be called once for each object being searched over. The subroutine should match the candidate against whatever
criteria you want and return true if it matches or false to skip. To do this, just pass your subroutine
coderef to C<where>.

To review the different types of queries, these are all equivalent to find all entries in the database titled
"My Bank":

    my $entries = $kdbx->entries->where(\'"My Bank"', 'eq', qw[title]);     # simple expression
    my $entries = $kdbx->entries->where(title => 'My Bank');                # declarative syntax
    my $entries = $kdbx->entries->where(sub { $_->title eq 'My Bank' });    # subroutine query

This is a trivial example, but of course your subroutine can be arbitrarily complex.

All of these query mechanisms described in this section are just tools, each with its own set of limitations.
If the tools are getting in your way, you can of course iterate over the contents of a database and implement
your own query logic, like this:

    my $entries = $kdbx->entries;
    while (my $entry = $entries->next) {
        if (wanted($entry)) {
            do_something($entry);
        }
        else {
            ...
        }
    }

=head2 Iteration

Iterators are the built-in way to navigate or walk the database tree. You get an iterator from L</entries>,
L</groups> and L</objects>. You can specify the search algorithm to iterate over objects in different orders
using the C<algorithm> option, which can be one of these L<constants|File::KDBX::Constants/":iteration">:

=over 4

=item *

C<ITERATION_IDS> - Iterative deepening search (default)

=item *

C<ITERATION_DFS> - Depth-first search

=item *

C<ITERATION_BFS> - Breadth-first search

=back

When iterating over objects generically, groups always precede their direct entries (if any). When the
C<history> option is used, current entries always precede historical entries.

If you have a database tree like this:

    Database
    - Root
        - Group1
            - EntryA
            - Group2
                - EntryB
        - Group3
            - EntryC

=over 4

=item *

IDS order of groups is: Root, Group1, Group2, Group3

=item *

IDS order of entries is: EntryA, EntryB, EntryC

=item *

IDS order of objects is: Root, Group1, EntryA, Group2, EntryB, Group3, EntryC

=item *

DFS order of groups is: Group2, Group1, Group3, Root

=item *

DFS order of entries is: EntryB, EntryA, EntryC

=item *

DFS order of objects is: Group2, EntryB, Group1, EntryA, Group3, EntryC, Root

=item *

BFS order of groups is: Root, Group1, Group3, Group2

=item *

BFS order of entries is: EntryA, EntryC, EntryB

=item *

BFS order of objects is: Root, Group1, EntryA, Group3, EntryC, Group2, EntryB

=back

=head1 SYNCHRONIZING

B<TODO> - This is a planned feature, not yet implemented.

=head1 ERRORS

Errors in this package are constructed as L<File::KDBX::Error> objects and propagated using perl's built-in
mechanisms. Fatal errors are propagated using L<perlfunc/"die LIST"> and non-fatal errors (a.k.a. warnings)
are propagated using L<perlfunc/"warn LIST"> while adhering to perl's L<warnings> system. If you're already
familiar with these mechanisms, you can skip this section.

You can catch fatal errors using L<perlfunc/"eval BLOCK"> (or something like L<Try::Tiny>) and non-fatal
errors using C<$SIG{__WARN__}> (see L<perlvar/%SIG>). Examples:

    use File::KDBX::Error qw(error);

    my $key = '';   # uh oh
    eval {
        $kdbx->load_file('whatever.kdbx', $key);
    };
    if (my $error = error($@)) {
        handle_missing_key($error) if $error->type eq 'key.missing';
        $error->throw;
    }

or using C<Try::Tiny>:

    try {
        $kdbx->load_file('whatever.kdbx', $key);
    }
    catch {
        handle_error($_);
    };

Catching non-fatal errors:

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    $kdbx->load_file('whatever.kdbx', $key);

    handle_warnings(@warnings) if @warnings;

By default perl prints warnings to C<STDERR> if you don't catch them. If you don't want to catch them and also
don't want them printed to C<STDERR>, you can suppress them lexically (perl v5.28 or higher required):

    {
        no warnings 'File::KDBX';
        ...
    }

or locally:

    {
        local $File::KDBX::WARNINGS = 0;
        ...
    }

or globally in your program:

    $File::KDBX::WARNINGS = 0;

You cannot suppress fatal errors, and if you don't catch them your program will exit.

=head1 ENVIRONMENT

This software will alter its behavior depending on the value of certain environment variables:

=over 4

=item *

C<PERL_FILE_KDBX_XS> - Do not use L<File::KDBX::XS> if false (default: true)

=item *

C<PERL_ONLY> - Do not use L<File::KDBX::XS> if true (default: false)

=item *

C<NO_FORK> - Do not fork if true (default: false)

=back

=head1 SEE ALSO

=over 4

=item *

L<KeePass Password Safe|https://keepass.info/> - The original KeePass

=item *

L<KeePassXC|https://keepassxc.org/> - Cross-Platform Password Manager written in C++

=item *

L<File::KeePass> has overlapping functionality. It's good but has a backlog of some pretty critical bugs and lacks support for newer KDBX features.

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/chazmcgarvey/File-KDBX/issues>

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
