#!perl
use warnings;
use strict;

use Data::Dumper;
use Test::More tests => 2;

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

my $des = Devel::Examine::Subs->new(file => 't/sample.data');

my $end = $des->run({post_proc => ['subs', 'end_of_last_sub']});

is ($end, 51, "post_proc 'end_of_last_sub' properly returns last line num in last sub in file" );
