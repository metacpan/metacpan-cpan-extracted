########################################################################
# housekeeping
########################################################################

package Workhorse::Test;
use v5.22;

use File::Basename;
use Test::More;

########################################################################
# package variables
########################################################################

my $base    = basename $0, '.t';

########################################################################
# run the tests
########################################################################

my ( $pkg ) = $base =~ m{^ \d+ .+? lib \D (.+) [.]pm }x;

$pkg    =~ s{~}{::}g;

require_ok $pkg;

SKIP:
{
    $pkg->can( 'VERSION' )
    or skip "Module does not compile: $@" => 0;

    pass "$pkg can 'VERSION'";

    ok $pkg->VERSION, "$pkg has VERSION value";
};

done_testing

__END__
