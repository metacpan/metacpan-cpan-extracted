#!perl

use Mojolicious::Lite; # "strict", "warnings", "utf8" and Perl 5.10 features
use JSON::Schema::ToJSON;
use Mojo::JSON;

my $spec_uri    = shift || die "Need a spec URI: $0 <spec_uri> <base_path> [<example_key>]";
my $base        = shift || die "Need base path: $0 <spec_uri> <base_path> [<example_key>]";
my $example_key = shift;

plugin OpenAPI => {
	route    => app->routes->under( $base )->to( cb => sub { 1; } ),
	url      => $spec_uri,
	renderer => sub {
		my ( $c,$data ) = @_;

		if ( $data->{status} == 501 ) {

			my $spec = $c->openapi->spec;

			if (my ($response) = grep { /^2/ } sort keys(%{$spec->{'responses'}})) {
				my $schema = $spec->{'responses'}{$response}{schema};
				$data = JSON::Schema::ToJSON->new(
					example_key => 'x-example',
				)->json_schema_to_json( schema => $schema );
				$c->stash( status => $response );
			}
		}

		$data->{messages} = delete $data->{errors} if $data->{errors};
		return Mojo::JSON::encode_json( $data );
	},
};

app->start;
