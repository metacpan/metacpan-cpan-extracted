use strict ;
use Test ;


BEGIN {
	if ($ENV{PERL_INLINE_JAVA_JNI}){
		plan(tests => 0) ;
		exit ;
	}
	else{
		plan(tests => 4) ;
	}
}


use Inline Config => 
           DIRECTORY => './_Inline_test' ;

use Inline (
	Java => 't/shared.java',
	SHARED_JVM => 1,
	PORT => 17891
) ;


my $t = new t10() ;

{
	ok($t->{i}, 5) ;
	ok(! Inline::Java::i_am_JVM_owner()) ;
	Inline::Java::capture_JVM() ;
	ok(Inline::Java::i_am_JVM_owner()) ;
}

ok($t->__get_private()->{proto}->ObjectCount(), 1) ;
