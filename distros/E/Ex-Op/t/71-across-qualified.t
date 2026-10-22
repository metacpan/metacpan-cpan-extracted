#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use EO::Ops;
use Ops::Math ();
use Ops::Reexport ();
use Ex::Op ();

{
    package EO::Q::Qualified;
    sub run { my $r = Ops::Math::add(2, 2) . Ops::Math::plain_name(); $r }
}
is( EO::Q::Qualified::run(), '4plain', 'a fully qualified call with nothing imported' );
is_deeply( op_calls('EO::Q::Qualified::run'), [1, 1], '... the op is an op call' );

{
    package EO::Q::One;
    use Ops::Math qw(add);
    sub run { my $r = add(1, 2); $r }
    package EO::Q::Two;
    use Ops::Math qw(add);
    sub run { my $r = add(3, 4); $r }
}
is( EO::Q::One::run() + EO::Q::Two::run(), 10, 'one op imported into two packages' );
is( \&EO::Q::One::add, \&EO::Q::Two::add, '... is the same sub in both' );
is_deeply( [op_calls('EO::Q::One::run'), op_calls('EO::Q::Two::run')], [[1, 0], [1, 0]], '... and an op call in both' );

{
    package EO::Q::Re;
    use Ops::Reexport qw(add mul);
    sub run { my $r = mul(add(1, 2), 3); $r }
}
is( EO::Q::Re::run(), 9, 'an op exported again by a second module' );
is( \&EO::Q::Re::add, \&Ops::Math::add, '... is the first module\'s sub' );
ok( Ex::Op::is_op(\&EO::Q::Re::add), '... and an op' );
is_deeply( op_calls('EO::Q::Re::run'), [2, 0], '... and the calls are op calls' );

{
    package EO::Q::Local;
    use Ops::Math qw(add);
    sub run { my $r = add(1, 2); $r }
    sub run_local { no warnings 'redefine'; local *EO::Q::Local::add = sub { 'local' }; run() }
}
is( EO::Q::Local::run_local(), 'local', 'local on the importing glob: the call goes to the new sub' );
is( EO::Q::Local::run(), 3, '... and back to the op after' );

done_testing;
