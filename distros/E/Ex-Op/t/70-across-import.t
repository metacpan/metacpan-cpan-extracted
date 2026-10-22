#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use EO::Ops;

{
    package EO::By::Default;
    use Ops::Math;
    sub run { my $r = add(1, 2); $r }
}
is( EO::By::Default::run(), 3, 'an op imported by @EXPORT' );
is_deeply( op_calls('EO::By::Default::run'), [1, 0], '... is an op call in the importing package' );

{
    package EO::By::Name;
    use Ops::Math qw(mul neg plain_twice);
    sub run { my $r = mul(neg(2), 3) + plain_twice(5); $r }
}
is( EO::By::Name::run(), 4, 'ops and a plain sub imported by name' );
is_deeply( op_calls('EO::By::Name::run'), [2, 1], '... the ops are op calls and the plain sub is not' );

{
    package EO::By::Amp;
    use Ops::Math qw(&clamp);
    sub run { my $r = clamp(15, 0, 10); $r }
}
is( EO::By::Amp::run(), 10, 'an op imported as &name' );
is_deeply( op_calls('EO::By::Amp::run'), [1, 0], '... is an op call' );

{
    package EO::By::Tag;
    use Ops::Math qw(:arith);
    sub run { my $r = add(mul(2, 3), neg(1)); $r }
}
is( EO::By::Tag::run(), 5, 'ops imported by a tag' );
is_deeply( op_calls('EO::By::Tag::run'), [3, 0], '... are op calls' );

{
    package EO::By::Pattern;
    use Ops::Math qw(/^is_/ /^cl/);
    sub run { my @r = (is_even(4), is_even(3), clamp(-5, 0, 9)); \@r }
}
is_deeply( EO::By::Pattern::run(), [1, 0, 0], 'ops imported by a pattern' );
is_deeply( op_calls('EO::By::Pattern::run'), [3, 0], '... are op calls' );

{
    package EO::By::Negation;
    use Ops::Math qw(:all !plain_name !plain_twice);
    sub run { my $r = add(1, 1) . mul(2, 2) . (defined &plain_name ? 'leak' : ''); $r }
}
is( EO::By::Negation::run(), '24', 'a tag less names' );
is_deeply( op_calls('EO::By::Negation::run'), [2, 0], '... the ops are op calls' );

{
    package EO::By::DefaultAnd;
    use Ops::Math qw(:DEFAULT is_even);
    sub run { my $r = add(is_even(2), 1); $r }
}
is( EO::By::DefaultAnd::run(), 2, ':DEFAULT and a name' );
is_deeply( op_calls('EO::By::DefaultAnd::run'), [2, 0], '... are op calls' );

{
    package EO::By::List;
    use Ops::Math qw(add);
    sub run { my @r = map { add($_, 10) } 1 .. 3; \@r }
}
is_deeply( EO::By::List::run(), [11, 12, 13], 'an imported op in a map block' );

done_testing;
