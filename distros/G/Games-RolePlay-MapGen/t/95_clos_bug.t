use strict;
use Test;
use Games::RolePlay::MapGen;
use Games::RolePlay::MapGen::MapQueue;

my $map = new Games::RolePlay::MapGen;
   $map->set_generator( "XMLImport" ); print STDERR " [xml]";
   $map->generate( xml_input_file => "vis1.map.xml" ); 

my $queue = new Games::RolePlay::MapGen::MapQueue( $map );

my @tests;
for my $x (0 .. 9) {
for my $y (24 .. 37) {
    push @tests, [$x,$y];
}}

plan tests => 2*2*4*(int @tests);

# NOTE: on 11/19, I discovered that some of the closures that
# should have an LoS don't for some reason.  So I installed this
# test to track it down.

for my $t (@tests) {
for my $d (qw(n e s w)) {
    my $pl = eval { $queue->_closure_line_of_sight_pl( $t => [@$t, $d] ) }; ok( not $@ );
    my $xs = eval { $queue->_closure_line_of_sight_xs( $t => [@$t, $d] ) }; ok( not $@ );

    ok($pl); warn " \e[31m \$pl=$pl for ($t->[0],$t->[1]):$d \e[m\n" unless $pl;
    ok($xs); warn " \e[31m \$xs=$xs for ($t->[0],$t->[1]):$d \e[m\n" unless $xs;
}}
