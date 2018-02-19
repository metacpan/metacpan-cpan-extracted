use strict;
use warnings;
use Test::More tests => 24;

use Inline(
	Java => 'DATA',
	STUDY => ['java.util.HashMap', 'java.lang.String'],
	AUTOSTUDY => 1,
) ;

use Inline::Java qw(cast coerce) ;

my $t = new types7() ;

{
	my $t1 = new t17() ;
	
	is($t->func(5), "int") ;
	is($t->func(coerce("char", 5)), "char") ;
	is($t->func(55), "int") ;
	is($t->func("str"), "string") ;
	is($t->func(coerce("java.lang.StringBuffer", "str")), "stringbuffer") ;
	
	is($t->f($t->{hm}), "hashmap") ;
	is($t->f(cast("java.lang.Object", $t->{hm})), "object") ;
	
	is($t->f(["a", "b", "c"]), "string[]") ;
	
	is($t->f(["12.34", "45.67"]), "double[]") ;
	is($t->f(coerce("java.lang.Object", ['a'], "[Ljava.lang.String;")), "object") ;
	
	eval {$t->func($t1)} ; like($@, qr/Can't find any signature/) ;
	eval {$t->func(cast("int", $t1))} ; like($@, qr/Can't cast (.*) to a int/) ;
	
	my $t2 = new t27() ;
	is($t2->f($t2), "t1") ;
	is($t1->f($t2), "t1") ;
	is($t2->f($t1), "t2") ;
	is($t2->f(cast("t17", $t2)), "t2") ;

	is($t2->f($t1), "t2") ;

	# Here we should always get the more specific stuff
	is($t2->{i}, 7) ;
	is($t2->{j}, 3.1416) ;

	# So this should fail
	eval {$t2->{j} = "string"} ; like($@, qr/Can't convert/) ;

	# Interfaces
	my $al = $t1->get_al() ;
	is($t1->count($al), 0) ;

	my $hm = new java::util::HashMap() ;
	$hm->put('key', 'value') ;
	my $a = $hm->entrySet()->toArray() ;
	foreach my $e (@{$a}){
		is(cast('java.util.Map$Entry', $e)->getKey(), 'key') ;
	}

	my $str = new java::lang::String('test') ;
	is($str, 'test') ;
}

is($t->__get_private()->{proto}->ObjectCount(), 1) ;


__END__

__Java__


import java.util.* ;

class t17 {
	public int i = 5 ;
	public String j = "toto" ;

	public t17(){
	}

	public String f(t27 o){
		return "t1" ;
	}

	public void n(){
	}

	public ArrayList<Object> get_al(){
		return new ArrayList<Object>() ;
	}

	public int count(Collection c){
		return c.size() ;
	}
}


class t27 extends t17 {
	public int i = 7 ;
	public double j = 3.1416 ;

	public t27(){
	}

	public String f(t17 o){
		return "t2" ;
	}

	public void n(){
	}
}


class types7 {
	public HashMap hm = new HashMap() ;

	public types7(){
	}

	public String func(String o){
		return "string" ;
	}

	public String func(StringBuffer o){
		return "stringbuffer" ;
	}

	public String func(int o){
		return "int" ;
	}

	public String func(char o){
		return "char" ;
	}

	public	String f(HashMap o){
		return "hashmap" ;
	}

	public String f(Object o){
		return "object" ;
	}

	public String f(String o[]){
		return "string[]" ;
	}

	public String f(double o[]){
		return "double[]" ;
	}
}

