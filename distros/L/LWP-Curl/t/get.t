#!perl -T

use Test::More tests => 5;
use Test::Exception;
use URI::file;

BEGIN {
    delete @ENV{qw(PATH IFS CDPATH ENV BASH_ENV)}; # Placates taint-unsafe Cwd.pm in 5.6.1
    use_ok( 'LWP::Curl' );
}

my $lwpcurl = LWP::Curl->new( timeout => 5 );
isa_ok ( $lwpcurl, 'LWP::Curl' ) ;

my $uri = URI::file->new_abs( 't/get.html' )->as_string;

ok( $lwpcurl->get( $uri ) , "Fetched:  $uri" ) or die q{Can't get test page};
ok( $lwpcurl->get( $uri, "http://some.refer" ) , "Fetched:  $uri" ) or die q{Can't get test page};
throws_ok { $lwpcurl->get( "http://127.0.0.1:1337/fooquuxbar.xhtml" ) } 'Net::Curl::Easy::Code';
