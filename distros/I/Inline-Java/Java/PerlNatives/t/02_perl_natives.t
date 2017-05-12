use strict ;
use Test ;


BEGIN {
	plan(tests => 5) ;
}


use Inline Config =>
           DIRECTORY => './_Inline_test' ;

use Inline::Java qw(caught) ;

use Inline (
	Java => 'DATA',
) ;


eval {
	t121->init() ;
	my $t = new t121() ;
	ok($t->types_stub(1, 2, 3, 4, 5, 6, 1, 2, "1000"), 1024) ;
	ok($t->array_stub([34, 56], ["toto", "789"]), 789 + 34) ;

	my $t2 = new t1212() ;
	ok($t2->types_stub(1, 2, 3, 4, 5, 6, 1, 2, "1000"), 1024) ;

	ok($t->callback_stub(), "toto") ;
	ok($t->__get_private()->{proto}->ObjectCount(), 2) ;
} ;
if ($@){
	if (caught("java.lang.Throwable")){
		$@->printStackTrace() ;
		die("Caught Java Exception") ;
	}
	else{
		die $@ ;
	}
}


##################################

package t121 ;
sub types {
	my $this = shift ;

	my $sum = 0 ;
	map {$sum += $_} @_ ;
	return $sum ;
}


sub array {
	my $this = shift ;
	my $i = shift ;
	my $str = shift ;

	return $i->[0] + $str->[1] ;
}


sub callback {
	my $this = shift ;

	return $this->get_name() ;
}


package main ;
__DATA__

__Java__


import java.io.* ;
import org.perl.inline.java.* ;

class t121 extends InlineJavaPerlNatives {
    static public boolean got14(){
        return System.getProperty("java.version").startsWith("1.4") ;
    }

	public t121() throws InlineJavaException {
	}

	static public void init() throws InlineJavaException {
		init("test") ;
	}

	public String types_stub(byte b, short s, int i, long j, float f, double d,
        boolean x, char c, String str){
		return types(b, s, i, j, f, d, x, c, str) ;
	}
	public native String types(byte b, short s, int i, long j, float f, double d,
		boolean x, char c, String str) ;

	public String array_stub(int i[], String str[]){
		return array(i, str) ;
	}
	private native String array(int i[], String str[]) ;

	public String callback_stub(){
		return callback() ;
	}
	public native String callback() ;

	public String get_name(){
		return "toto" ;
	}
} ;


class t1212 extends t121 {
	public t1212() throws InlineJavaException {
	}
} ;
