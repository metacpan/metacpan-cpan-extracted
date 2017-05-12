use v5.14;
use warnings;
use Benchmark 'cmpthese';

package Using_FP {
	use Function::Parameters ':strict';
	method foo ( :$x, :$y ) {
		return [ $x, $y ];
	}
}

package Using_Kavorka {
	use Kavorka;
	method foo ( :$x, :$y ) {
		return [ $x, $y ];
	}
}

cmpthese(-3, {
	Using_FP               => q{ Using_FP->foo(x => 1, y => $_) for 0..99 },
	Using_Kavorka_Hash     => q{ Using_Kavorka->foo(x => 1, y => $_) for 0..99 },
	Using_Kavorka_Hashref  => q{ Using_Kavorka->foo({x => 1, y => $_ }) for 0..99 },
});

__END__
                       Rate Using_Kavorka_Hashref Using_Kavorka_Hash    Using_FP
Using_Kavorka_Hashref 270/s                    --               -10%        -65%
Using_Kavorka_Hash    302/s                   12%                 --        -61%
Using_FP              768/s                  184%               155%          --
