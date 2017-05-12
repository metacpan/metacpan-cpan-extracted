package t10 ;

use strict ;
use Test ;


BEGIN {
	# Leave previous server enough time to die...
	sleep(1) ;
	require Inline::Java::Portable ;
	if ($ENV{PERL_INLINE_JAVA_JNI}){
		plan(tests => 0) ;
		exit ;
	}
	elsif (! Inline::Java::Portable::portable('GOT_FORK')){
		plan(tests => 0) ;
		exit ;
	}
	else{
		$t10::nb = 5 ;
		plan(tests => $t10::nb + 3) ;
	}
}


use Inline Config => 
           DIRECTORY => './_Inline_test' ;

use Inline (
	Java => 't/shared.java',
	SHARED_JVM => 1,
	PORT => 17891,
	NAME => 't10',
) ;


$t10::t10::i = 0 ;

my $nb = $t10::nb ;
my $sum = (($nb) * ($nb + 1)) / 2 ;
for (my $i = 0 ; $i < $nb ; $i++){
	if (! fork()){
		do_child($i) ;
	}
}


# Wait for kids to finish
for (my $i = 0 ; $i < $nb ; $i++){
	wait() ;
	ok(1) ;
}

ok($t10::t10::i, $sum) ;

# Bring down the JVM
ok(! Inline::Java::i_am_JVM_owner()) ;
Inline::Java::capture_JVM() ;
ok(Inline::Java::i_am_JVM_owner()) ;


sub do_child {
	my $i = shift ;

	Inline::Java::reconnect_JVM() ;

	my $t = new t10::t10() ;
	for (my $j = 0 ; $j <= $i ; $j++){
		$t->incr() ;
	}
	exit ;
}
