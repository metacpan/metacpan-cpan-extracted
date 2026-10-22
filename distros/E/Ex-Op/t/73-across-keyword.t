#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;

BEGIN { plan skip_all => 'the op keyword needs perl 5.14' if $] < 5.014 }

use EO::Ops;
use Ex::Op ();

{
    package EO::K::All;
    use Ops::MathKw qw(:all);
    sub run { my $r = kadd(kclamp(50, 0, 10), 1) . kname(); $r }
}
is( EO::K::All::run(), '11kw', 'ops made with the keyword, imported by a tag' );
is_deeply( op_calls('EO::K::All::run'), [2, 1], '... are op calls, and the plain sub is not' );
ok( Ex::Op::is_op(\&EO::K::All::kclamp), '... the one with returns too' );

done_testing;
