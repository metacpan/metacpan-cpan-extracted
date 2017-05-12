#!perl -T

use Test::More tests => 5;
use URI::file;

BEGIN {
    delete @ENV{qw(PATH IFS CDPATH ENV BASH_ENV)}; # Placates taint-unsafe Cwd.pm in 5.6.1
    use_ok( 'LWP::Curl' );
}

my $lwpcurl = LWP::Curl->new();
isa_ok ( $lwpcurl, 'LWP::Curl' ) ;
cmp_ok( $lwpcurl->timeout, '==', 180 );
cmp_ok( $lwpcurl->auto_encode, '==', 1);
is( $lwpcurl->proxy, undef);
