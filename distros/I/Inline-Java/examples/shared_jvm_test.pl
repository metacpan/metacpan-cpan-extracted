package shared_jvm_test ;

use strict ;

use blib ;

use Inline (
	Java => 'DATA',
	NAME => "shared_jvm_test",
	SHARED_JVM => 1,
) ;

$shared_jvm_test::t::i = 0 ;

my $nb = 10 ;
my $sum = (($nb) * ($nb + 1)) / 2 ;
for (my $i = 0 ; $i < $nb ; $i++){
	if (! fork()){
		print STDERR "." ;
		shared_jvm_test::do_child($i) ;
	}
}


# Wait for kids to finish
for (my $i = 0 ; $i < 5 ; $i++){
	sleep(1) ;
	print STDERR "." ;
}
print STDERR "\n" ;

if ($shared_jvm_test::t::i == $sum){
	print STDERR "Test succeeded\n" ;
}
else{
	print STDERR "Test failed ($shared_jvm_test::t::i != $sum)\n" ;
}


sub do_child {
	my $i = shift ;

	Inline::Java::reconnect_JVM() ;

	my $t = new shared_jvm_test::t() ;
	my $j = 0 ;
	for ( ; $j <= $i ; $j++){
		$t->incr_i() ;
	}
	exit ;
}


__DATA__

__Java__


import java.util.* ;

class t {
	static public int i = 0 ;

	public t(){
	}

	public void incr_i(){
		i++ ;
	}
}
