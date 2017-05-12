use 5.14.0;
use warnings;

package MyKavorkaParamTraitTest {
    use Moops;

    class Class using Moose {

        method square(Int $integer does doc('The integer to square.') --> Int does doc('The integer squared.')) {
            return $integer * $integer;
        }
    }
}
