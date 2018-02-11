use strict ;
use Test ;

use Inline (
	Java => 'DATA',
) ;

use Inline::Java qw(caught) ;
use Data::Dumper ;


BEGIN {
	my $cnt = 21 ;
	plan(tests => $cnt) ;
}

my $t = new t16() ;

{
	eval {
		my $o = new O::b::j(name => 'toto') ;
		$t->set($o) ;
		ok($t->get(), $o) ;
		ok($t->get()->{name}, 'toto') ;
		check_count(1) ; # po

		ok($t->round_trip($o), $o) ;
		check_count(2) ; # po + 1 leaked object

		ok($t->method_call($o, 'get', ['name']), 'toto') ;
		check_count(2) ; # po + 1 leaked object

		ok($t->add_eval(5, 6), 11) ;
		check_count(2) ; # po + 1 leaked object

		eval {$t->method_call($o, 'bad', ['bad'])} ; ok($@, qr/Can't locate object method "bad" via package "O::b::j"/) ;
		check_count(3) ; # po + $o + 1 leaked object
		eval {$t->round_trip({})} ; ok($@, qr/^Can't convert (.*?) to object org.perl.inline.java.InlineJavaPerlObject/) ;
		eval {$t->error()} ; ok($@, qr/alone/) ;

		check_count(3) ; # po + 2 leaked objects
		$t->dispose($o) ;
		check_count(2) ; # 2 leaked objects

		my $jo = $t->create("O::b::j", ['name', 'titi']) ;
		ok($jo->get("name"), 'titi') ;
		$t->have_fun() ;
		ok($jo->get('shirt'), qr/lousy t-shirt/) ;
		check_count(3) ; # po + 2 leaked objects

		$t->dispose(undef) ;
		check_count(2) ; # 2 leaked objects
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
}

ok($t->__get_private()->{proto}->ObjectCount(), 1) ;
check_count(2) ; # 2 leaked objects


sub check_count {
	ok($_[0], Inline::Java::Callback::ObjectCount()) ;
}


sub debug_objects {
	map {print "$_\n"} %{Inline::Java::Callback::__GetObjects()} ;
}


package O::b::j ;

sub new {
	my $class = shift ;

	return bless({@_}, $class) ;
}

sub get {
	my $this = shift ;
	my $attr = shift ;

	return $this->{$attr} ;
}

sub set {
	my $this = shift ;
	my $attr = shift ;
	my $val = shift ;

	$this->{$attr} = $val ;
}

package main ;


__END__

__Java__


import org.perl.inline.java.* ;

class t16 {
	InlineJavaPerlObject po = null ;

	public t16(){
	}

	public void set(InlineJavaPerlObject o){
		po = o ;
	}

	public InlineJavaPerlObject get(){
		return po ;
	}

	public int add_eval(int a, int b) throws InlineJavaException, InlineJavaPerlException {
		Integer i = (Integer)po.eval(a + " + " + b, Integer.class) ;
		return i.intValue() ;
	}

	public String method_call(InlineJavaPerlObject o, String name, Object args[]) throws InlineJavaException, InlineJavaPerlException {
		String s = (String)o.InvokeMethod(name, args) ;
		o.Dispose() ;
		return s ;
	}

	public void error() throws InlineJavaException, InlineJavaPerlException {
		po.eval("die 'alone'") ;
	}

	public InlineJavaPerlObject round_trip(InlineJavaPerlObject o) throws InlineJavaException, InlineJavaPerlException {
		return o ;
	}

	public void dispose(InlineJavaPerlObject o) throws InlineJavaException, InlineJavaPerlException {
		if (o != null){
			o.Dispose() ;
		}
		if (po != null){
			po.Dispose() ;
		}
	}

	public InlineJavaPerlObject create(String pkg, Object args[]) throws InlineJavaException, InlineJavaPerlException {
		po = new InlineJavaPerlObject(pkg, args) ;
		return po ;
	}

	public void have_fun() throws InlineJavaException, InlineJavaPerlException {
		po.InvokeMethod("set", new Object [] {"shirt", "I've been to Java and all I got was this lousy t-shirt!"}) ;
	}
}
