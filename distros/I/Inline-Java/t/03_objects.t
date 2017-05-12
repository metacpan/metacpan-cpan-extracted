use strict ;
use Test ;

use Inline Config => 
           DIRECTORY => './_Inline_test';

use Inline(
	Java => 'DATA',
) ;


BEGIN {
	plan(tests => 16) ;
}


# Create some objects
my $t = new types3() ;

{
	my $obj1 = new obj13() ;
	eval {my $obj2 = new obj23()} ; ok($@, qr/No public constructor/) ;
	my $obj11 = new obj113() ;
	
	ok($t->_obj1(undef), undef) ;
	ok($t->_obj1($obj1)->get_data(), "obj1") ;
	ok($t->_obj11($obj11)->get_data(), "obj11") ;
	ok($t->_obj1($obj11)->get_data(), "obj11") ;
	eval {$t->_int($obj1)} ; ok($@, qr/Can't convert (.*) to primitive int/) ;
	eval {$t->_obj11($obj1)} ; ok($@, qr/is not a kind of/) ;

	# Inner class
	my $in = new obj13::inner_obj13($obj1) ;
	ok($in->{data}, "inner") ;
	
	# Receive an unbound object and send it back
	my $unb = $t->get_unbound() ;
	ok($t->send_unbound($unb), "al_elem") ;
	
	# Unexisting method
	eval {$t->toto()} ; ok($@, qr/No public method/) ;
	
	# Method on unbound object
	eval {$unb->toto()} ; ok($@, qr/Can't call method/) ;
	
	# Incompatible prototype, 1 signature
	eval {$t->_obj1(5)} ; ok($@, qr/Can't convert/) ;
	
	# Incompatible prototype, >1 signature
	eval {$t->__obj1(5)} ; ok($@, qr/Can't find any signature/) ;
	
	# Return a scalar hidden in an object.
	ok($t->_olong(), 12345) ;

	# Pass a non-Java object, a hash ref.
	my $d = {} ;
	eval {$t->_Object($d)} ; ok($@, qr/Can't convert/) ;
}

ok($t->__get_private()->{proto}->ObjectCount(), 1) ;


__END__

__Java__

import java.util.* ;


class obj13 {
	String data = "obj1" ;

	public obj13() {
	}

	public String get_data(){
		return data ;
	}

	public class inner_obj13 {
		public String data = "inner" ;

		public inner_obj13(){
		}
	}
}

class obj113 extends obj13 {
	String data = "obj11" ;

	public obj113() {
	}

	public String get_data(){
		return data ;		
	}
}


class obj23 {
	String data = "obj2" ;

	obj23() {
	}

	public String get_data(){
		return data ;		
	}
}


class types3 {
	public types3(){
	}

	public int _int(int i){
		return i + 1 ;
	}

	public Object _Object(Object o){
		return o ;
	}

	public obj13 _obj1(obj13 o){
		return o ;
	}


	public obj13 __obj1(obj13 o, int i){
		return o ;
	}


	public obj13 __obj1(obj13 o){
		return o ;
	}


	public obj113 _obj11(obj113 o){
		return o ;
	}

	public ArrayList get_unbound(){
		ArrayList al = new ArrayList() ;
		al.add(0, "al_elem") ;

		return al ;
	}

	public String send_unbound(ArrayList al){
		return (String)al.get(0) ;
	}

	public Object _olong(){
		return new Long("12345") ;
	}
}
