use strict;
use warnings;
use utf8;

use Test::More;
$ENV{AUTHOR_TESTING} && eval { require Test::NoWarnings };

BEGIN {
    @MAIN::methods = qw(ceiling flight_rule);
    plan tests => ( 4 + @MAIN::methods ) + 1;
    ok(1);
    use_ok('Geo::METAR::Deduced');
}
diag("Testing Geo::METAR::Deduced $Geo::METAR::Deduced::VERSION");
my $obj = new_ok('Geo::METAR::Deduced');

@Geo::METAR::Deduced::Sub::ISA = qw(Geo::METAR::Deduced);
my $obj_sub = new_ok('Geo::METAR::Deduced::Sub');

foreach my $method (@MAIN::methods) {
    can_ok( 'Geo::METAR::Deduced', $method );
}

my $msg = 'Author test. Set $ENV{AUTHOR_TESTING} to a true value to run.';
SKIP: {
    skip $msg, 1 unless $ENV{AUTHOR_TESTING};
}
$ENV{AUTHOR_TESTING} && Test::NoWarnings::had_no_warnings();
