use strict ;
use Test ;

use Inline Config => 
           DIRECTORY => './_Inline_test' ;


package t02_14 ;
use Inline(
    Java => qq |
        class t02_14 {
            public static boolean got14(){
				try {
					Class c = Class.forName("java.lang.CharSequence") ;
				}
				catch (ClassNotFoundException cnfe){
					return false ;
				}
				return true ;
			}
        }
    |,
    NAME => 't02_14',
) ;


package main ;
BEGIN {
	my $got14 = t02_14::t02_14->got14() ;
	if (! $got14){
		plan(tests => 0) ;
		exit(0) ;
	}

	plan(tests => 4) ;
}



use Inline(
    Java => 'DATA',
) ;



my $t = new types2_1() ;

{
	ok($t->_CharSequence(undef), undef) ;
	ok($t->_CharSequence(0), "0") ;
	ok($t->_CharSequence("charsequence"), "charsequence") ;
}

ok($t->__get_private()->{proto}->ObjectCount(), 1) ;




__END__

__Java__

class types2_1 {
	public types2_1(){
	}

	public CharSequence _CharSequence(CharSequence c){
		return c ;
	}
}


