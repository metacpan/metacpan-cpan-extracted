# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# check partition_to_string
# check distinguishes
# check G
# check partition
# check partition_subsets

use Test;
BEGIN { plan tests => 57 };
use Graph::ModularDecomposition qw(partition_to_string);

#########################

ok partition_to_string( [['a'], ['b','c'], ['ab','d','c']] ), 'a,ab+c+d,b+c';

my $g = new Graph::ModularDecomposition;
$g->add_vertex( 'a' );

ok not $g->distinguishes('a','a','a');

$g->add_vertex( 'b' );

eval {
    open(STDERR, ">/dev/null") if -w '/dev/null';
    $g->debug(3);
    ok not $g->distinguishes('a','a','b');

    $g->add_edge( 'a', 'c' );
    ok $g->distinguishes('a','b','c');
    ok $g->distinguishes('c','a','b');
    ok not $g->distinguishes('b','a','c');
    $g->debug(0);
};

ok $g->distinguishes('c','b','a');

$g->add_edges( qw(a d b d) );

ok $g->distinguishes('a','b','c');
ok not $g->distinguishes('a','c','d');
ok $g->distinguishes('b','c','d');
ok not $g->distinguishes('b','a','c');

ok $g->G('a'), 'b-d,c-b,c-d,d-c';
ok $g->G('b'), 'a-c,a-d,c-a,d-c';
ok $g->G('c'), 'a-b,b-d,d-a,d-b';
$g->debug(3);
ok $g->G('d'), 'a-b,b-a,b-c,c-a';
$g->debug(0);

ok partition_to_string( $g->partition('a') ), 'b,c,d';
ok partition_to_string( $g->partition('b') ), 'a,c,d';
ok partition_to_string( $g->partition('c') ), 'a,b,d';
$g->debug(3);
ok partition_to_string( $g->partition('d') ), 'a,b,c';
$g->debug(0);

$g->add_vertex( 'e' );

ok partition_to_string( $g->partition('a') ), 'b,c,d,e';
ok partition_to_string( $g->partition('b') ), 'a,c,d,e';
ok partition_to_string( $g->partition('c') ), 'a,b,d,e';
ok partition_to_string( $g->partition('d') ), 'a,b,c,e';
ok partition_to_string( $g->partition('e') ), 'a+b+c+d';

$g->add_edge( 'e', 'b' );

ok partition_to_string( $g->partition('a') ), 'b,c,d,e';
ok partition_to_string( $g->partition('b') ), 'a,c,d,e';
ok partition_to_string( $g->partition('c') ), 'a,b,d,e';
ok partition_to_string( $g->partition('d') ), 'a,b,c,e';
ok partition_to_string( $g->partition('e') ), 'a,b,c,d';

$g->add_edge( 'e', 'd' );

ok partition_to_string( $g->partition('a') ), 'b+e,c,d';
ok partition_to_string( $g->partition('b') ), 'a,c,d,e';
ok partition_to_string( $g->partition('c') ), 'a,b+e,d';
ok partition_to_string( $g->partition('d') ), 'a,b+e,c';
ok partition_to_string( $g->partition('e') ), 'a,b,c,d';

$g->add_edges( qw(e g f g f d g d) );

ok $g->G('a'), 'b-d,b-e,c-b,c-d,c-e,c-f,c-g,d-c,e-b,e-d,e-g,f-d,f-g,g-d,g-e,g-f';
ok $g->G('b'), 'a-c,a-d,c-a,d-c,e-a,e-c,e-f,f-d,f-g,g-d,g-e,g-f';
ok $g->G('c'), 'a-b,a-e,a-f,a-g,b-d,b-e,d-a,d-b,d-e,d-f,d-g,e-b,e-d,e-g,f-d,f-g,g-d,g-e,g-f';
ok $g->G('d'), 'a-b,a-e,a-f,a-g,b-a,b-c,b-e,b-f,b-g,c-a,e-a,e-c,e-f,f-a,f-b,f-c,f-e,g-a,g-b,g-c,g-e,g-f';
ok $g->G('e'), 'a-c,a-d,b-a,b-c,b-d,b-f,b-g,c-a,d-c,f-d,f-g,g-a,g-b,g-c,g-d';
ok $g->G('f'), 'a-c,a-d,b-d,b-e,c-a,d-c,e-b,e-d,e-g,g-a,g-b,g-c,g-d';
ok $g->G('g'), 'a-c,a-d,b-d,b-e,c-a,d-c,e-a,e-c,e-f,f-a,f-b,f-c,f-e';

ok partition_to_string( [$g->partition_subsets([qw(a b c d)],'e')] ),
'a+c,b+d';
ok partition_to_string( [$g->partition_subsets([qw(a c d e)],'b')] ),
'a+c,d,e';
ok partition_to_string( [$g->partition_subsets([qw(b c d e f g)],'a')] ),
'b+e+f+g,c+d';
ok partition_to_string( [$g->partition_subsets([qw(b c d e)],'a')] ),
'b+e,c+d';
ok partition_to_string( [$g->partition_subsets([qw(a b c d e f)],'g')] ),
'a+b+c,d,e+f';
ok partition_to_string( [$g->partition_subsets([qw(a b c d e)],'g')] ),
'a+b+c,d,e';
ok partition_to_string( [$g->partition_subsets([qw(a b c d e f g)],'a')] ),
'a+b+e+f+g,c+d';

ok partition_to_string( $g->partition('a') ), 'b+e+f+g,c,d';
ok partition_to_string( $g->partition('b') ), 'a,c,d,e,f,g';
ok partition_to_string( $g->partition('c') ), 'a,b+e+f+g,d';
ok partition_to_string( $g->partition('d') ), 'a,b+e+f+g,c';
ok partition_to_string( $g->partition('e') ), 'a,b,c,d,f,g';
ok partition_to_string( $g->partition('f') ), 'a,b,c,d,e,g';
ok partition_to_string( $g->partition('g') ), 'a,b,c,d,e,f';

$g->add_edge( qw(c a) );
$g->debug(3);
ok partition_to_string( $g->partition('a') ), 'b+e+f+g,c,d';
$g->debug(0);
ok partition_to_string( $g->partition('a') ), 'b+e+f+g,c,d';

