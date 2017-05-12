use strict;
use warnings;
use Test::More;
require "./t/Util.pm";
t::Util->import();
use HTTP::Entity::Parser;
use Cwd;
use File::Spec::Functions;
use Hash::MultiValue;

my $path = catdir( getcwd(), 't', '02_http_body', 'data', 'urlencoded' );

for my $i ( 1..6 ) {
    my $test    = sprintf( "%03d", $i );

    my $headers = paml_loadfile( catfile( $path, "$test-headers.pml" ) );
    open( my $content, '<:unix', catfile( $path, "$test-content.dat" ) );
    my $results = paml_loadfile( catfile( $path, "$test-results.pml" ) );
    my $env = build_env($headers, $content);

    my $parser = HTTP::Entity::Parser->new();
    $parser->register('application/x-www-form-urlencoded','HTTP::Entity::Parser::UrlEncoded');
    my ($params, $uploads) = $parser->parse($env);

    my $hash = Hash::MultiValue->new(@$params);
    is_deeply([$hash->keys], $results->{param_order}, "[$i] param_order");
    is_deeply($hash->as_hashref_mixed, $results->{param}, "[$i] param");
    is_deeply($uploads, []);
}

done_testing;
