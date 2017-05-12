use strict ;
use Test ;

use Inline Config => 
           DIRECTORY => './_Inline_test';

use Inline(
	Java => 'DATA',
) ;

use Inline::Java qw(caught) ;


BEGIN {
	# Leave previous server enough time to die...
	sleep(1) ;
	plan(tests => 8) ;
}


my $t = new t9(0) ;

{
	my $msg = '' ;
	eval {
		$t->f() ;
	} ;
	if ($@){
		if (caught("java.io.IOException")){
			$msg = $@->getMessage() . "io" ;
		}
		elsif (caught("java.lang.Exception")){
			$msg = $@->getMessage() ;
		}
		else {
			die $@ ;
		}
	} ;
	ok($msg, "from fio") ;

	$msg = '' ;
	eval {
		$t->f() ;
	} ;
	if ($@){
		if (caught("java.lang.Throwable")){
			$msg = $@->getMessage() ;
		}
		elsif (caught("java.io.IOException")){
			$msg = $@->getMessage() . "io" ;
		}
		else {
			die $@ ;
		}
	}
	ok($msg, "from f") ;


	$msg = '' ;
	eval {
		die("not e\n") ;
	} ;
	if ($@){
		if (caught("java.lang.Exception")){
			$msg = $@->getMessage() ;
		}
		else {
			$msg = $@ ;
		}
	}
	ok($msg, "not e\n") ;


	my $e = $t->f2() ;
	ok($e->getMessage(), "from f2") ;


	$msg = '' ;
	eval {
		my $t2 = new t9(1) ;
	} ;
	if ($@){
		if (caught("java.lang.Exception")){
			$msg = $@->getMessage() ;
		}
		else{
			die $@ ;
		}
	}
	ok($msg, "from const") ;	

	# Undeclared exception, java.lang.NullPointerException
	$msg = '' ;
	eval {
		my $t2 = new t9(0) ;
		$t2->len(undef) ;
	} ;
	if ($@){
		if (caught("java.lang.NullPointerException")){
			$msg = "null" ;
		}
		else {
			die $@ ;
		}
	}
	ok($msg, "null") ;	

	# Undeclared exception, java.lang.NullPointerException
	$msg = '' ;
	eval {
		my $t2 = new t9(0) ;
		$t2->len(undef) ;
	} ;
	if ($@){
		if (caught("java.lang.IOException")){
			$msg = "io" ;
		}
		elsif (caught("java.lang.Exception")){
			$msg = "null" ;
		}
		else{
			die $@ ;
		}
	}
	ok($msg, "null") ;

	# Make sure the last exception is not lying around...
	$@ = undef ;
}

ok($t->__get_private()->{proto}->ObjectCount(), 1) ;


__END__

__Java__


import java.io.* ;

class t9 {
	public t9(boolean t) throws Exception {
		if (t){
			throw new Exception("from const") ;
		}
	}

	public String f() throws IOException {
		throw new IOException("from f") ;
	}

	public IOException f2() {
		return new IOException("from f2") ;
	}

	public int len(String s) {
		return s.length() ;
	}
}

