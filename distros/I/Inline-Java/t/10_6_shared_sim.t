package t10 ;

use strict ;
use Test ;


use Inline Config => 
           DIRECTORY => './_Inline_test';


BEGIN {
	# Leave previous server enough time to die...
	sleep(1) ;
	if ($ENV{PERL_INLINE_JAVA_JNI}){
		plan(tests => 0) ;
		exit ;
	}
	else{
		plan(tests => 7) ;
	}
}



Inline->bind(
	Java => 't/shared.java',
	SHARED_JVM => 1,
	PORT => 17891,
	NAME => 't10',
) ;
{
	my $t = new t10::t10() ;
	ok($t->{i}++, 5) ;
	ok(! Inline::Java::i_am_JVM_owner()) ;
}
my $JVM1 = Inline::Java::__get_JVM() ;
$JVM1->{destroyed} = 1 ;
Inline::Java::__clear_JVM() ;


Inline->bind(
	Java => 't/shared.java',
	SHARED_JVM => 1,
	PORT => 17891,
	NAME => 't10',
) ;
{
	my $t = new t10::t10() ;
	ok($t->{i}++, 6) ;
	ok(! Inline::Java::i_am_JVM_owner()) ;
}
my $JVM2 = Inline::Java::__get_JVM() ;
$JVM2->{destroyed} = 1 ;
Inline::Java::__clear_JVM() ;


Inline->bind(
	Java => 't/shared.java',
	SHARED_JVM => 1,
	PORT => 17891,
	NAME => 't10',
) ;
{
	my $t = new t10::t10() ;
	ok($t->{i}, 7) ;
	ok(! Inline::Java::i_am_JVM_owner()) ;
	Inline::Java::capture_JVM() ;
	ok(Inline::Java::i_am_JVM_owner()) ;
}
