use strict;
use Test::More tests => 2;

my $class;
my @tests = qw( t/GD-Graph-sparklines.t );
BEGIN {
    $class = 'GD::Graph::sparklines';
    use_ok($class)
}

my $f = $class->new;
isa_ok($f, $class);
