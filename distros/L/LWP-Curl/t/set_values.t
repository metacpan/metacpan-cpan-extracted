#!perl -T

use Test::More tests => 4;
use URI::file;

BEGIN {
    delete @ENV{qw(PATH IFS CDPATH ENV BASH_ENV)}; # Placates taint-unsafe Cwd.pm in 5.6.1
    use_ok( 'LWP::Curl' );
}

my $lwpcurl = LWP::Curl->new( headers => 1,
                              user_agent => "Foo",
                              maxredirs => 10,
                              followlocation => 0,
                              proxy => "http://localhost:3128");
isa_ok ( $lwpcurl, 'LWP::Curl' ) ;
$lwpcurl->timeout(42);
cmp_ok( $lwpcurl->timeout, '==', 42 );
$lwpcurl->proxy('http://127.0.0.1:3128');
cmp_ok( $lwpcurl->proxy, 'eq', 'http://127.0.0.1:3128');
