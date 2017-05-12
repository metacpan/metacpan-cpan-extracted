#!perl -T

use Test::More tests => 2;
use URI::file;
use Test::Exception;

BEGIN {
    delete @ENV{qw(PATH IFS CDPATH ENV BASH_ENV)}; # Placates taint-unsafe Cwd.pm in 5.6.1
    use_ok( 'LWP::Curl' );
}
throws_ok { LWP::Curl->new( {} ) } qr/not hash reference/;
