use Test::Simple 'no_plan';
use strict;
use lib './lib';
use LEOCHARRE::CLI2 qw/:all/,'abc';

ok(1,'compiled');

my @o;
@o = opt_selected();

ok( 1, "no opts.");



warn "\n\n";

$OPT{a} = 1;

ok( @o = opt_selected(), "yes had opts '@o'");

ok( opt_selected('a'), 'opt_selected() with argument');
ok( ! opt_selected(qw/a b/), 'opt_selected() with argument');
ok( ! opt_selected(qw/b/), 'opt_selected() with argument');


ok( ! opt_selected([qw//]), 'opt_selected() with argument');

