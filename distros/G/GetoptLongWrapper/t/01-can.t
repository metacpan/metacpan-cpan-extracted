#!perl
use 5.006;
use strict;
use warnings;
use Test::More; # tests => 2; # qw/no_plan/;
use lib 'lib';

plan tests => 1;

BEGIN {
    use_ok( 'GetoptLongWrapper' ) || print "Bail out!\n";
}

use GetoptLongWrapper;
my %H=();
my $gow=new GetoptLongWrapper(undef, \%H);
ok($gow->can('init_getopts'));
done_testing();
