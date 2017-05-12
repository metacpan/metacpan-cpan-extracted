#!perl

use warnings;
use strict;

use Lexical::Persistence;

use Test::More tests => 9;

my $lp = Lexical::Persistence->new();

is( $lp->do( '1 + 2' ), 3, 'constant do' );

$lp->do( 'my $three = 3' );
is_deeply( $lp->get_context('_'), { '$three' => 3 }, 'do sets context' );

my $code = $lp->compile( '$three' );
is( ref $code, 'CODE', 'compile yields a CODE ref' );

is( $lp->call( $code ), 3, 'CODE ref yields the right result' );

is( $lp->do( '$three + 4' ), 7, 'do still persists' );

$lp->do( '$three = 10' );
is( $lp->do( '$three' ), 10, 'do updates' );

$lp->do( 'my @list' );
is_deeply( $lp->get_context('_'), { '$three' => 10, '@list' => [], }, 'do can add new variables' );

$code = $lp->compile( '$four' );
my $err = "$@";

is( $code, undef, 'syntax error makes do return undef' );
like( $err, qr/^Global symbol "\$four" requires explicit package name/, 'syntax error complains about variable names' );
