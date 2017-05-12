use Test::More tests => 1;

use Math::Brent qw(Brentzero);
use Math::Utils qw(:compare :polynomial);
use strict;
use warnings;

my $fltcmp = generate_fltcmp(5e-7);
my $brent_tol = 1e-8;
my $r;

sub wobble
{
	my($t) = @_;
	return $t - cos($t);
}

$r = Brentzero(0.5, 1.0, \&wobble, $brent_tol);
ok(&$fltcmp($r, 0.739085133) == 0, "wobble() claimed zero at $r");

1;
