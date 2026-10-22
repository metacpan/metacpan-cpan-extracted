#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use B::Concise ();

BEGIN { plan skip_all => 'the op keyword needs perl 5.14' if $] < 5.014 }

use Ex::Op;

sub lit { 'L' }

op add ($x, $y) { $x + $y }
op zero () { 0 }
op seven { 7 }
op spaced (  $a1 ,$b2  )
{
    # a comment in the body
    $a1 . '-' . $b2;
}
op EO::Kw::qual ($v) { return "<$v>" }
op with_return ($n) { return 'small' if $n < 10; 'big' }
op tail_call ($n) { lit() }
op uses_wantarray ($n) { wantarray ? 'list' : 'scalar' }

sub calls { my $r = add(2, 3); [$r, zero(), seven(), spaced(1, 2), EO::Kw::qual('q'),
            with_return(5), with_return(50), tail_call(1)] }
is_deeply( calls(), [5, 0, 7, '1-2', '<q>', 'small', 'big', 'L'], 'each shape of op runs' );

for my $name (qw(add zero seven spaced EO::Kw::qual with_return tail_call)) {
    no strict 'refs';
    ok( Ex::Op::is_op(\&{$name}), "$name is an op" );
}

is( Ex::Op::why_not(\&uses_wantarray), 'it calls wantarray', 'a body an op cannot run stays a plain sub, with the reason' );
is( scalar(uses_wantarray(1)), 'scalar', '... and runs as one' );
my @l = uses_wantarray(1);
is_deeply( \@l, ['list'], '... in list context too' );

my $out = '';
B::Concise::walk_output(\$out);
B::Concise::compile('-exec', 'main::calls')->();
my @calls = $out =~ /\bexop_call\b/g;
is( scalar @calls, 8, q{calls compiled after the ops are op calls} );

{
    my @w;
    local $SIG{__WARN__} = sub { push @w, @_ };
    eval q{
        package EO::Kw::Same;
        use Ex::Op;
        op one ($x) { $x + 1 }
        BEGIN { Ex::Op::make(two => sub { my ($x) = @_; $x + 1 }) }
        sub both { [one(1), two(1)] }
        1;
    } or die $@;
    is_deeply( EO::Kw::Same::both(), [2, 2], 'the keyword and make give the same op' );
    is( scalar @w, 0, '... with no warnings' );
}

{
    my $ok = eval q{
        package EO::Kw::Strict;
        use Ex::Op 'strict';
        op bad ($x) { caller }
        1;
    };
    ok( !$ok, "under 'strict' a declined op dies" );
    like( $@, qr/^bad cannot be an op: it calls caller at /, '... with the name and the reason' );
}

SKIP: {
    skip 'utf8 names', 2 unless eval q{ use utf8; 1 };
    my $r = eval q{
        package EO::Kw::Utf8;
        use utf8;
        use Ex::Op;
        op dœ ($ñ) { $ñ * 2 }
        sub run { dœ(21) }
        run();
    };
    is( $r, 42, 'utf8 names for the op and its parameters' ) or diag $@;
    ok( eval q{ use utf8; Ex::Op::is_op(\&EO::Kw::Utf8::dœ) }, '... and it is an op' );
}

done_testing;
