use strict;
use warnings;
use utf8;

use Test::More;
use Test::Warn;
$ENV{AUTHOR_TESTING} && eval { require Test::NoWarnings };

use version;

use Geo::METAR::Deduced;

plan tests => (4) + 1;

my $m = new Geo::METAR::Deduced;
$m->metar(q{KFDY 251450Z 21012G21KT 8SM OVC065 04/M01 A3010 RMK 57014});
is( $m->SITE,   q{KFDY} );
is( $m->DATE,   q{25} );
is( $m->MOD,    q{AUTO} );
is( $m->TEMP_F, q{39.2} );

my $msg = 'Author test. Set $ENV{AUTHOR_TESTING} to a true value to run.';
SKIP: {
    skip $msg, 1 unless $ENV{AUTHOR_TESTING};
}
$ENV{AUTHOR_TESTING} && Test::NoWarnings::had_no_warnings();
