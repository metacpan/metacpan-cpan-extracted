#!perl

use Mojolicious::Lite; # "strict", "warnings", "utf8" and Perl 5.10 features
use JSON::Schema::ToJSON;

my $spec_uri    = shift || die "Need a spec URI: $0 <spec_uri> <base_path> [<example_key>]";
my $base        = shift || die "Need base path: $0 <spec_uri> <base_path> [<example_key>]";
my $example_key = shift;

plugin OpenAPI => {
	route => app->routes->under( $base )->to( cb => sub { 1; } ),
	url   => $spec_uri,
};

app->helper( 'openapi.not_implemented' => sub {

	if ( my $responses = shift->openapi->spec->{'responses'} ) {
		if ( my ( $response ) = grep { /^2/ } sort keys( %{$responses} ) ) {

			my $ret = $responses->{$response}{description} // '';
			if ( my $schema = $responses->{$response}{schema} ) {
				$ret = JSON::Schema::ToJSON->new->json_schema_to_json(
					schema      => $schema,
					example_key => $example_key,
				);
			}
			return {json => $ret, status => $response};
		}
	}

	return {
		status => 501,
		json   => {errors => [{message => 'Not implemented.', path => '/'}]}
	};
});


app->start;
