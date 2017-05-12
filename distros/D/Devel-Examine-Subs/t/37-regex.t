#!perl 
use warnings;
use strict;

use Data::Dumper;
use Test::More tests => 4;
use Test::Trap;

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

my $des = Devel::Examine::Subs->new(
                            file => 't/sample.data',
                          );

my $ret = $des->has(search => q/\$str = 'this'/);

is (@$ret, 2, "regex captures properly");

$ret = $des->has(search => q/\$x\s+\*\s+\$y/);

is (@$ret, 1, "complex regex with vars match");

#$ret = $des->has({regex => 0, search => 'this', config_dump => 1});
$ret = $des->has(regex => 0, search => '$x * $y');

is (@$ret, 1, "regex => 0 does the right thing");





