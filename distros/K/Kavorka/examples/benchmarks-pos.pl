use v5.14;
use warnings;
use Benchmark 'cmpthese';

package Using_FP {
	use Function::Parameters ':strict';
	method foo ( $x, $y ) {
		return [ $x, $y ];
	}
}

package Using_Kavorka {
	use Kavorka;
	method foo ( $x, $y ) {
		return [ $x, $y ];
	}
}

cmpthese(-3, {
	Using_FP       => q{ Using_FP->foo(1, $_) for 0..99 },
	Using_Kavorka  => q{ Using_Kavorka->foo(1, $_) for 0..99 },
});

__END__
                Rate Using_Kavorka      Using_FP
Using_Kavorka 1450/s            --          -11%
Using_FP      1637/s           13%            --
