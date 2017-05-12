#! perl

use Benchmark;
use Math::Erf::Approx erf => { -as => 'mea_erf' };
use Games::Go::Erf qw<erf>;

BENCHMARK: {
	timethese(100_000 => {
		MEA  => sub { mea_erf( rand(3.0) ) },
		GGE  => sub { erf( rand(3.0) ) },
	});
};

print <DATA>

__DATA__

Things that the speed tests don't tell you:

1. Games::Go::Erf is part of Games::Go::GoPair and thus has
   a dependency on Tk.

2. Games::Go::Erf sets $[ to 1, which has been deprecated
   since Perl 5.12.

3. Games::Go::Erf calculates erf() with greater accuracy than
   Math::Erf::Approx.

4. Games::Go::Erf can calculate inverses.
