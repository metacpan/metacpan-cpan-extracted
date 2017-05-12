use strict;
use warnings;
use Test::More;
require "./t/Util.pm";
t::Util->import();
use HTTP::Entity::Parser;
use Cwd;
use File::Spec::Functions;
use Hash::MultiValue;

my $path = catdir( getcwd(), 't', '02_http_body', 'data', 'multipart' );

for my $i ( 1..15 ) {
    my $test    = sprintf( "%03d", $i );

    my $headers = paml_loadfile( catfile( $path, "$test-headers.pml" ) );
    open(my $content, '<:unix', catfile( $path, "$test-content.dat" ) );
    my $results;
    if ( -f catfile( $path, "$test-results.pml" ) ) {
        $results = paml_loadfile( catfile( $path, "$test-results.pml" ) );
    }
    my $env = build_env($headers, $content);

    my $parser = HTTP::Entity::Parser->new();
    $parser->register('multipart/form-data','HTTP::Entity::Parser::MultiPart');
    my ($params, $uploads);
    eval {
        ($params, $uploads) = $parser->parse($env);
    };
    if ( $results ) {
        ok(!$@);
        my $hash = Hash::MultiValue->new(@$params);
        is_deeply([$hash->keys], $results->{param_order}, "[$i] param_order");
        is_deeply($hash->as_hashref_mixed, $results->{param}, "[$i] param");

        my $upload_hash = Hash::MultiValue->new(@$uploads);
        $upload_hash->each(sub {
            delete $_[1]->{tempname};
            my $headers = delete $_[1]->{headers};
            my %headers = @$headers;
            $_[1]->{headers} = \%headers;
        });
        
        is_deeply($upload_hash->as_hashref_mixed, $results->{upload} || {}, "[$i] upload");

    }
    else {
        ok($@);
    }
}

done_testing;

