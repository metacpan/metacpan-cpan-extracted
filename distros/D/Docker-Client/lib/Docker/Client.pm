package Docker::Client;

use Moose;
use Moose::Util::TypeConstraints;

use Carp;

use Array::Utils qw( array_minus );
use Class::Inspector;
use OpenAPI::Client;

use File::ShareDir qw( dist_dir );

use Mojo::File;
use Mojo::URL;

our $VERSION = '0.1.1';

class_type 'Mojo::URL';
coerce 'Mojo::URL', from 'Str', via { Mojo::URL->new(shift) };

has 'endpoint' => (
    is      => 'ro',
    isa     => 'Mojo::URL',
    default => sub {
        return Mojo::URL->new('http+unix://%2Fvar%2Frun%2Fdocker.sock');
    },
    coerce => 1,
);

has 'version' => (
    is  => 'ro',
    isa => enum(
        [
            'v1.40', 'v1.39', 'v1.38', 'v1.37', 'v1.36', 'v1.35',
            'v1.34', 'v1.33', 'v1.32', 'v1.31', 'v1.30', 'v1.29',
            ,        'v1.28', 'v1.27', 'v1.26', 'v1.25',
        ]
    ),
    default => 'v1.40',
);

has 'ua' => (
    is      => 'ro',
    isa     => 'Mojo::UserAgent',
    lazy    => 1,
    default => sub {
        return shift->api()->ua();
    },
);

has 'api' => (
    is      => 'ro',
    isa     => 'OpenAPI::Client',
    lazy    => 1,
    default => sub {
        my $self = shift;

        ## Making sure we use the correct version path
        my $base_url =
          $self->endpoint()->clone()->path( sprintf '/%s', $self->version() );

        ## Loading correct version specification from disk.
        my $spec =
          Mojo::File->new( dist_dir('Docker-Client') )->child('specs')
          ->child( sprintf '%s.yaml', $self->version() );

        ## Creating the OpenAPI Client instance using the defined parameters.
        my $api =
          OpenAPI::Client->new( $spec->to_string(),
            base_url => $self->endpoint() );

        ## If the protocol is local we need to replace the "Host" header on each request
        if ( $self->endpoint()->protocol() eq 'http+unix' ) {
            $api->ua()->on(
                start => sub {
                    my ( $ua, $tx ) = @_;

                    $tx->req()->headers()->header( 'Host' => 'localhost' );
                }
            );
        }

        return $api;
    },
);

sub BUILD {
    my $self = shift;

    ## Making sure we extract only the methods corresponding to the OpenAPI definition.
    my $api_methods  = Class::Inspector->methods( ref $self->api(),  'public' );
    my $base_methods = Class::Inspector->methods( 'OpenAPI::Client', 'public' );

    my @methods = array_minus( @{$api_methods}, @{$base_methods} );
    croak 'No methods found!'
      unless ( scalar @methods );

    ## Creating corresponding methods names in the current instance.
    foreach my $name (@methods) {
        $self->meta()->add_method(
            $name,
            sub {
                return shift->api()->$name(@_);
            }
        );
    }

    return;
}

no Moose;
no Moose::Util::TypeConstraints;

1;

__END__

