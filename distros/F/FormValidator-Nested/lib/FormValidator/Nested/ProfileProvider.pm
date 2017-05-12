package FormValidator::Nested::ProfileProvider;
use Any::Moose '::Role';
use Any::Moose 'X::AttributeHelpers';
use namespace::clean -except => 'meta';
use FormValidator::Nested::Profile;

use Hash::Merge;
my $behavior = {
    SCALAR => {
        SCALAR => sub { $_[1] },
        ARRAY  => sub { [ @{$_[1]} ] },
        HASH   => sub { $_[1] }
    },
    ARRAY => {
        SCALAR => sub { $_[1] },
        ARRAY  => sub { [ @{$_[1]} ] },
        HASH   => sub { $_[1] }
    },
    HASH => {
        SCALAR => sub { $_[1] },
        ARRAY  => sub { [ @{$_[1]} ] },
        HASH   => sub { Hash::Merge::_merge_hashes( $_[0], $_[1] ) }
    },
};
Hash::Merge::specify_behavior($behavior);

requires 'get_profile_data';

has '_profiles' => (
    metaclass => 'Collection::Hash',
    is        => 'rw',
    isa       => 'HashRef[FormValidator::Nested::Profile]',
    default   => sub { {} },
    provides  => {
        set    => '_set_profile',
        get    => '_get_profile',
        exists => '_exists_profile',
    },
);
has 'profile_keys' => (
    metaclass => 'Collection::Array',
    is        => 'rw',
    isa       => 'ArrayRef[Str]',
    lazy_build => 1,
    provides  => {
        elements => 'get_profile_keys',
        push     => 'push_profile_keys',
    },
);
has 'init_read_all_profile' => (
    is  => 'ro',
    isa => 'Bool',
    default => 0,
);
has 'visitor' => (
    is         => 'ro',
    isa        => 'Data::Visitor::Callback',
);
has 'filter' => (
    is         => 'ro',
    isa        => 'CodeRef',
);

sub BUILD {
    my $self = shift;

    if ( $self->init_read_all_profile ) {
        $self->read_all_profile;
    }
}


sub read_all_profile {
    my $self = shift;

    foreach my $profile_key ( $self->get_profile_keys ) {
        $self->get_profile($profile_key);
    }
}

sub get_profile {
    my $self = shift;
    my $key  = shift;

    if ( !$self->_exists_profile($key) ) {
        my $data = $self->get_profile_data($key);
        if ( !$data ) {
            return 0;
        }
        if ( $self->visitor ) {
            $data = $self->visitor->visit($data);
        }
        if ( $self->filter ) {
            $self->filter->($data);
        }

        if ( $data->{extends} ) {
            $data = Hash::Merge::merge($self->get_profile($data->{extends})->data, $data);
        }

        $self->_set_profile($key => FormValidator::Nested::Profile->new({
            provider => $self,
            key      => $key,
            data     => $data,
        }));
    }

    return $self->_get_profile($key);
}

1;

