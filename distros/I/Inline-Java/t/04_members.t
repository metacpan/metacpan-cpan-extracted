use strict ;
use Test::More tests => 28;

use Inline(
	Java => 'DATA',
) ;

use Inline::Java qw(cast);

my $t = new types4() ;

{
	$t->{_byte} = 123 ;
	cmp_ok($t->{_byte}, '==', 123) ;
	$t->{_Byte} = 123 ;
	cmp_ok($t->{_Byte}, '==', 123) ;
	
	$t->{_short} = 123 ;
	cmp_ok($t->{_short}, '==', 123) ;
	$t->{_Short} = 123 ;
	cmp_ok($t->{_Short}, '==', 123) ;
	
	$t->{_int} = 123 ;
	cmp_ok($t->{_int}, '==', 123) ;
	$t->{_Integer} = 123 ;
	cmp_ok($t->{_Integer}, '==', 123) ;
	
	$t->{_long} = 123 ;
	cmp_ok($t->{_long}, '==', 123) ;
	$t->{_Long} = 123 ;
	cmp_ok($t->{_Long}, '==', 123) ;
	
	$t->{_float} = 123.456 ;
	cmp_ok($t->{_float}, '==', 123.456) ;
	$t->{_Float} = 123.456 ;
	cmp_ok($t->{_Float}, '==', 123.456) ;
	
	$t->{_double} = 123.456 ;
	cmp_ok($t->{_double}, '==', 123.456) ;
	$t->{_Double} = 123.456 ;
	cmp_ok($t->{_Double}, '==', 123.456) ;
	
	$t->{_boolean} = 1 ;
	ok($t->{_boolean}) ;
	$t->{_Boolean} = 1 ;
	ok($t->{_Boolean}) ;
	
	$t->{_char} = "a" ;
	is($t->{_char}, "a") ;
	$t->{_Character} = "a" ;
	is($t->{_Character}, "a") ;
	
	$t->{_String} = "string" ;
	is($t->{_String}, "string") ;
	$t->{_StringBuffer} = "stringbuffer" ;
	is($t->{_StringBuffer}, "stringbuffer") ;
	
	my $obj1 = obj14->new;
	$t->{_Object} = $obj1 ;
	is(cast('obj14', $t->{_Object})->get_data(), "obj1") ;
	$t->{_Object} = "object" ;
	is($t->{_Object}, "object") ;
	
	$t->{_Object} = undef ;
	is($t->{_Object}, undef) ;
	$t->{_int} = undef ;
	cmp_ok($t->{_int}, '==', 0) ;
	
	# Receive an unbound object and try to call a member
	my $unb = $t->get_unbound() ;
	eval {$unb->{toto} = 1} ; like($@, qr/Can't set member/) ;
	eval {my $a = $unb->{toto}} ; like($@, qr/Can't get member/) ;
	
	# Unexisting member
	eval {$t->{toto} = 1} ; like($@, qr/No public member/) ;
	eval {my $a = $t->{toto}} ; like($@, qr/No public member/) ;
	
	# Incompatible type
	eval {$t->{_long} = $obj1} ; like($@, qr/Can't convert/) ;
}

is($t->__get_private()->{proto}->ObjectCount(), 1) ;

__END__

__Java__

import java.util.* ;

class obj14 {
	String data = "obj1" ;

	public obj14() {
	}

	public String get_data(){
		return data ;		
	}
}


class types4 {
	public byte _byte ;
	public Byte _Byte ;
	public short _short ;
	public Short _Short ;
	public int _int ;
	public Integer _Integer ;
	public long _long ;
	public Long _Long ;
	public float _float ;
	public Float _Float ;
	public double _double ;
	public Double _Double ;
	public boolean _boolean ;
	public Boolean _Boolean ;
	public char _char ;
	public Character _Character ;
	public String _String ;
	public StringBuffer _StringBuffer ;
	public Object _Object ;

	public types4(){
	}

	public ArrayList get_unbound(){
		ArrayList al = new ArrayList() ;
		al.add(0, "al_elem") ;

		return al ;
	}

	public String send_unbound(ArrayList al){
		return (String)al.get(0) ;
	}
}

