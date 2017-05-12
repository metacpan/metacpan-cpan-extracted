use strict ;
use Test ;

use Inline Config => 
           DIRECTORY => './_Inline_test' ;

use Inline (
	Java => 'DATA',
	NATIVE_DOUBLES => 2,
) ;


BEGIN {
	plan(tests => 3) ;
}


my $t = new t15() ;

{
	# Here it is hard to test for accuracy, but either it works or it doesn't...
	ok($t->_Double(0.056200000000000028) > 0.056) ;
	ok($t->_Double(0.056200000000000028) < 0.057) ;
}

ok($t->__get_private()->{proto}->ObjectCount(), 1) ;




__END__

__Java__

class t15 {
	public t15(){
	}

	public Double _Double(Double d){
		return d ;
	}
}


