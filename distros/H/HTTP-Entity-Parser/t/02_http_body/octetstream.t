use strict;
use warnings;
use Test::More;
require "./t/Util.pm";
t::Util->import();
use HTTP::Entity::Parser;
use Cwd;
use File::Spec::Functions;
use Hash::MultiValue;

my $path = catdir( getcwd(), 't', '02_http_body', 'data', 'octetstream' );

for my $i ( 1..3 ) {
    my $test    = sprintf( "%03d", $i );

    my $headers = paml_loadfile( catfile( $path, "$test-headers.pml" ) );
    open(my $content, '<:unix',catfile( $path, "$test-content.dat" ) );
    my $results = slurp( catfile( $path, "$test-results.dat" ) );
    my $env = build_env($headers, $content);

    my $parser = HTTP::Entity::Parser->new();
    $parser->register('application/octet-stream','HTTP::Entity::Parser::OctetStream');
    my ($params, $uploads) = $parser->parse($env);

    my $hash = Hash::MultiValue->new(@$params);
    is_deeply([$hash->keys], [], "[$i] param_order");
    is_deeply($hash->as_hashref_mixed, {}, "[$i] param");
    is_deeply($uploads, []);
    my $data = do {
        local $/;
        my $fh = $env->{'psgi.input'};
        <$fh>;
    };
    is($data, $results);
}

done_testing;
