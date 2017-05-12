use warnings;
use strict;

use Test::More tests => 5*6;

BEGIN { $^H |= 0x20000 if "$]" < 5.008; }

$SIG{__WARN__} = sub { die "WARNING: $_[0]" };

# The \5 test fails unfairly under MAD+threads due to [perl #109746].
my $bug109746 = do { my $a = \123; my $b = \$$a; $a != $b };

our $x = undef;
our $y = 1;
our($oref, $aref, $bref, $cref, $dref);
foreach(
	\$x,
	\$y,
	do { my $x = 6; \$x },
	sub { my $x = 7; \$x }->(),
	$bug109746 ? "skip" : \5,
	\undef,
) { SKIP: {
	skip "[perl #109746]", 5 if ref($_) eq "" && $_ eq "skip";
	$oref = $_;
	$aref = $bref = $cref = $dref = undef;
	eval q{
		use Lexical::Var '$foo' => $oref;
		$aref = \$foo;
		$bref = \$foo;
		# A srefgen op applied to a const op will undergo
		# constant folding.  This screws up some test cases.
		# So we also test with list-type refgen, which won't
		# be constant-folded.
		($cref, undef) = \($foo, 1);
		($dref, undef) = \($foo, 2);
	};
	is $@, "";
	ok $aref == $oref;
	ok $bref == $oref;
	ok $cref == $oref;
	ok $dref == $oref;
} }

1;
