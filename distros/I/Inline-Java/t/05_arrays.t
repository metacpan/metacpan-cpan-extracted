use strict ;
use Test ;

use Inline Config => 
           DIRECTORY => './_Inline_test';

use Inline(
	Java => 'DATA'
) ;

BEGIN {
	plan(tests => 55) ;
}


my $t = new types5() ;

{
	ok(++($t->_byte([12, 34, 56])->[0]) == 124) ;
	ok(eq_array($t->_Byte([12, 34, 56]), [12, 34, 56])) ;
	ok(++($t->_short([12, 34, 56])->[0]) == 124) ;
	ok(eq_array($t->_Short([12, 34, 56]), [12, 34, 56])) ;
	ok(++($t->_int([12, 34, 56])->[0]) == 124) ;
	ok(eq_array($t->_Integer([12, 34, 56]), [12, 34, 56])) ;
	ok(++($t->_long([12, 34, 56])->[0]) == 124) ;
	ok(eq_array($t->_Long([12, 34, 56]), [12, 34, 56])) ;
	ok(++($t->_float([12.34, 5.6, 7])->[0]) == 124.456) ;
	ok(eq_array($t->_Float([12.34, 5.6, 7]), [12.34, 5.6, 7])) ;
	ok(++($t->_double([12.34, 5.6, 7])->[0]) == 124.456) ;
	ok(eq_array($t->_Double([12.34, 5.6, 7]), [12.34, 5.6, 7])) ;
	ok($t->_boolean([1, 0, "tree"])->[0]) ;
	ok($t->_Boolean([1, 0])->[0]) ;
	ok(! $t->_Boolean([1, 0])->[1]) ;
	ok($t->_char(['a', 'b', 'c'])->[0], "A") ;
	ok(eq_array($t->_Character(['a', 'b', 'c']), ['a', 'b', 'c'], 1)) ;
	my $a = $t->_String(["bla", "ble", "bli"]) ;
	ok($a->[0], "STRING") ;
	$a->[1] = "wazoo" ;
	ok($a->[1], "wazoo") ;
	ok($t->_StringBuffer(["bla", "ble", "bli"])->[0], "STRINGBUFFER") ;
	
	ok($t->_Object(undef), undef) ;
	$a = $t->_Object([1, "two", $t]) ;
	ok($a->[0], "1") ;
	ok($a->[1], "two") ;
	ok(UNIVERSAL::isa($a->[2], "main::types5")) ;
	ok($a->[2]->{data}->[1], "a") ;
	$a->[2]->{data} = ["1", "2"] ;
	ok($a->[2]->{data}->[1], 2) ;

	$a->[0]++ ;
	ok($a->[0], "2") ;

	$a->[1] = "three" ;
	ok($a->[1], "three") ;

	$a->[2] = "string" ;
	ok($a->[2], "string") ;

	$a->[0] = $t ;
	ok(UNIVERSAL::isa($a->[0], "main::types5")) ;
	
	# Try some multidimensional arrays.
	$a = $t->_StringString([
		["00", "01"],
		["10", "11"]
	]) ;
	
	# Try some incomplete multidimensional arrays.
	$a = $t->_StringString([
		[undef, "01", "02"],
		[undef, "11"],
		undef,
	]) ;
	ok($a->[1]->[0], undef) ;
	
	
	my $b = $a->[1] ;
	ok($t->_String($b)->[0], "STRING") ;
	
	# Arrays of other arrays
	$a = $t->_StringString([
		$a->[0],
	]) ;
	ok($a->[0]->[2], "02") ;
	
	# This is one of the things that won't work. 
	# Try passing an array as an Object.
	eval {$t->_o(["a", "b", "c"])} ; ok($@, qr/Can't create Java array/) ;
	ok($t->_o(Inline::Java::coerce(
		"java.lang.Object", 
		["a", "b", "c"], 
		"[Ljava.lang.String;"))->[0], "a") ;
	$t->{o} = Inline::Java::coerce(
		"java.lang.Object", 
		["a", "b", "c"], 
		"[Ljava.lang.String;") ;
	ok($t->{o}->[0], "a") ;
	$t->{o} = $t->{i} ;
	ok($t->{o}->[0], "1") ;
	
	# Mixed types
	eval {$t->_int(["3", "3456", "cat"])} ; ok($@, qr/Can't convert/) ;
	ok($t->_Object(["3", "3456", "cat"])->[2], 'cat') ; 
	
	# Badly constructed array
	eval {$t->_int(["3", [], "cat"])} ; ok($@, qr/Java array contains mixed types/) ;
	eval {$t->_StringString([["3"], "string"])} ; ok($@, qr/Java array contains mixed types/) ;
	
	# Invalid operations on arrays.
	eval {@{$b} = ()} ; ok($@, qr/Operation CLEAR/) ;
	eval {pop @{$b}} ; ok($@, qr/Operation POP/) ;
	eval {shift @{$b}} ; ok($@, qr/Operation SHIFT/) ;
	eval {splice(@{$b}, 0, 1)} ; ok($@, qr/Operation SPLICE/) ;
	eval {$b->[10] = 5} ; ok($@, qr/out of bounds/) ;

	# Cool stuff on arrays
	$a = $t->_byte([12, 34, 56]) ;
	ok(scalar(@{$a}), 3) ;
	foreach my $e (@{$a}){
		ok($e =~ /^(123|34|56)$/) ;
	}

	# Zero length arrays
	$a = $t->_Byte([]) ;
	ok(scalar(@$a), 0) ;
	$a = $t->_StringString([[], []]) ;
	ok(scalar(@{$a}), 2) ;
	ok(scalar(@{$a->[0]}), 0) ;
	ok(scalar(@{$a->[1]}), 0) ;
}

ok($t->__get_private()->{proto}->ObjectCount(), 1) ;


sub eq_array {
	my $a1 = shift ;
	my $a2 = shift ;
	my $eq = shift || 0 ;

	if (scalar(@{$a1}) != scalar(@{$a2})){
		return 0 ;
	}

	my $ok = 1 ;
	for (0..$#{$a1}){
		if ($eq){
			$ok = ($a1->[$_] eq $a2->[$_]) ;
		}
		else{
			$ok = ($a1->[$_] == $a2->[$_]) ;
		}
		last unless $ok ;
	}
	
	return $ok ;
}


__END__

__Java__


class types5 {
	public Object o ;
	public int i[] = {1, 2, 3} ;
	public String data[] = {"d", "a", "t", "a"} ;
	public types5(){
	}

	public byte[] _byte(byte b[]){
		b[0] = (byte)123 ;
		return b ;
	}

	public Byte[] _Byte(Byte b[]){
		return b ;
	}

	public short[] _short(short s[]){
		s[0] = (short)123 ;
		return s ;
	}

	public Short[] _Short(Short s[]){
		return s ;
	}

	public int[] _int(int i[]){
		i[0] = 123 ;
		return i ;
	}

	public Integer[] _Integer(Integer i[]){
		return i ;
	}

	public long[] _long(long l[]){
		l[0] = 123 ;
		return l ;
	}

	public Long[] _Long(Long l[]){
		return l ;
	}

	public float[] _float(float f[]){
		f[0] = (float)123.456 ;
		return f ;
	}

	public Float[] _Float(Float f[]){
		return f ;
	}

	public double[] _double(double d[]){
		d[0] = 123.456 ;
		return d ;
	}

	public Double[] _Double(Double d[]){
		return d ;
	}

	public boolean[] _boolean(boolean b[]){
		b[0] = true ;
		return b ;
	}

	public Boolean[] _Boolean(Boolean b[]){
		return b ;
	}

	public char[] _char(char c[]){
		c[0] = 'A' ;
		return c ;
	}

	public Character[] _Character(Character c[]){
		return c ;
	}

	public String[] _String(String s[]){
		s[0] = "STRING" ;
		return s ;
	}

	public String[][] _StringString(String s[][]){
		return s ;
	}

	public StringBuffer[] _StringBuffer(StringBuffer sb[]){
		sb[0] = new StringBuffer("STRINGBUFFER") ;
		return sb ;
	}

	public Object[] _Object(Object o[]){
		return o ;
	}

	public Object _o(Object o){
		return o ;
	}
}
