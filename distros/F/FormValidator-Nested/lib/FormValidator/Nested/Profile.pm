package FormValidator::Nested::Profile;
use Any::Moose;
use Any::Moose 'X::AttributeHelpers';
use namespace::clean -except => 'meta';

use FormValidator::Nested::Result;
use FormValidator::Nested::Profile::Param;

use Class::Param;

use Carp;

has 'provider' => (
    is       => 'ro',
    isa      => 'FormValidator::Nested::ProfileProvider',
    required => 1,
    weak_ref => 1,
);
has 'key' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);
has 'data' => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
);
has 'params' => (
    metaclass  => 'Collection::Hash',
    is         => 'ro',
    isa        => 'HashRef[FormValidator::Nested::Profile::Param]',
    lazy_build => 1,
    provides   => {
        values   => 'get_params',
        get      => 'get_param',
    },
);
__PACKAGE__->meta->make_immutable;

sub BUILD {
    my $self = shift;
    
    # paramsの初期化
    $self->params;
}

sub _build_params {
    my $self = shift;
    my %params = ();
    while ( my ( $param_key, $param_data ) = each %{$self->data->{params}} ) {
        $params{$param_key} = FormValidator::Nested::Profile::Param->new({
            profile => $self,
            key     => $param_key,
            name    => $param_data->{name} || '',
            array   => $param_data->{array},
            $param_data->{nested} ? (
                nested => $self->provider->get_profile($param_data->{nested}),
            ) : (),
            data    => $param_data,
        });
    }
    return \%params;
}


sub validate {
    my ( $self, $req, $parent_names ) = @_;

    if ( blessed($req) ) {
        if ( !$req->can('param') ) {
            croak("req cannot call param method.");
        }
    }
    elsif ( ref $req eq 'HASH' ) {
        $req = Class::Param->new($req);
    }

    my $result = FormValidator::Nested::Result->new;

    foreach my $param ( $self->get_params ) {
        $result->merge($param->validate($req, $parent_names));
    }

    return $result;
}


1;

