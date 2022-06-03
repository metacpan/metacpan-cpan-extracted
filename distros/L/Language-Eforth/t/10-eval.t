#!perl
use Test2::V0;

use Language::Eforth;
my $f = Language::Eforth->new;

$f->eval("2 2 +\n");
my ( $value, $ret ) = $f->pop;
is( $value, 4 );
is( $ret,   0 );

( $value, $ret ) = $f->pop;
is( $value, 0 );
is( $ret,   -4 );    # see "Error Codes" in embed.fth

is( [ $f->push(39) ], [ 1, 0 ] );
$f->push(3);
is( $f->depth, 2 );

$f->eval("+\n");
( $value, $ret ) = $f->pop;
is( $value, 42 );
is( $ret,   0 );

is( $f->depth, 0 );

$f->push(99);
$f->reset;
is( $f->depth, 0 );

# embed_push, embed_pop deal with uint16_t so this should not change to
# -11215 (unless you run it through signed())
$f->eval("54321\n");
is( scalar $f->pop, 54321 );

# push in v0.02 accepts multiple arguments, for better or worse
is( [ $f->push(qw/1 2 3 4/) ], [ 4, 0 ] );
is( [ $f->drain ],             [qw/4 3 2 1/] );

# SvIOK may fail on qw/1 2 3 4/ so was removed as a check in v0.02.
# maybe instead use looks_like_number? but that accepts Inf and other
# such nonesense. this may trigger a "Argument "%s" isn't numeric"
# warning (perldoc perldiag) if you are passing strings that become 0
# into ->push
diag "one janky use of string-as-number coming right up";
$f->push("li no");    # Lojban for "the number 0"
is( [ $f->pop ], [ 0, 0 ] );

# utility functions and that the sign (or lack thereof) through push/pop
# is correct
$f->push(54321);
my $x = $f->pop;
my $y = Language::Eforth::signed($x);
my $z = Language::Eforth::unsigned($y);
is( [ $z, $y, $x ], [ 54321, -11215, 54321 ] );
# and that drain uses the same logic as pop
$f->push(54321);
is( [ $f->drain ], [54321] );

# NOTE pretty sure this is a bug in embed, see KLUGE in Eforth.xs
my $e = Language::Eforth->new;
$e->push(7);
$e->push(1);
$e->eval("+\n");
is( scalar $e->pop, 8 );

# ->new may die but causing malloc to fail would take more effort than
# I'm willing to spend. also if you're that starved for memory why not
# run something like Forth directly on the hardware?

like( dies { $e->eval },        qr/Usage/ );
like( dies { $e->eval(undef) }, qr/empty expression/ );
like( dies { $e->eval("") },    qr/empty expression/ );

like( dies { $e->push },        qr/nothing/ );
like( dies { $e->push(undef) }, qr/defined/ );

done_testing 22
