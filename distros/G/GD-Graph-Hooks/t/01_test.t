
use strict;
use Test;

plan tests => 4;

my $rv1 = eval "use GD::Graph::Hooks; 9";
my $rv2 = eval "use GD::Graph::lines; 9";

my $rv3 = eval q /
    my $graph = GD::Graph::lines->new(500,500);
    $graph->add_hook( 'GD::Graph::Hooks::PRE_DATA' => sub { ok(1) } );
    $graph->plot([[1..3], [1..3]]);

9/;

ok( "rv1 $rv1 $@", "rv1 9 " );
ok( "rv2 $rv2 $@", "rv2 9 " );
ok( "rv3 $rv3 $@", "rv3 9 " );
