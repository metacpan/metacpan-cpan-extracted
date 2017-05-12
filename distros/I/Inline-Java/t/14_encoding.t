use strict ;
use Test ;

use Inline Config => 
           DIRECTORY => './_Inline_test' ;

use Inline (
	Java => 'DATA'
) ;


BEGIN {
	plan(tests => 9) ;
}


my $t = new t14() ;

{
	ok($t->_String("A"), "A") ;
	ok($t->_String("\x{41}"), "A") ;
	ok($t->_String("A"), "\x{41}") ;

	# This is E9 (233), which is e acute. Although the byte
	# E9 is invalid in UTF-8, the character 233 is valid and 
	# all should work out.
	ok($t->_String("\x{E9}"), "\x{E9}") ;
	my $a = $t->toCharArray("\x{E9}") ;
	ok(ord($a->[0]) == 233) ;

	# Send a unicode escape sequence.
	ok($t->_String("\x{263A}"), "\x{263A}") ;

	# Generate some binary data
	my $bin = '' ;
	for (my $i = 0; $i < 256 ; $i++) {
		my $c = chr($i) ;
		$bin .= $c ;
	}
	ok($t->_String($bin), $bin) ;

	# Mix it up
	ok($t->_String("$bin\x{E9}\x{263A}"), "$bin\x{E9}\x{263A}") ;

}

ok($t->__get_private()->{proto}->ObjectCount(), 1) ;




__END__

__Java__

class t14 {
	public t14(){
	}

	public String _String(String s){
		return s ;
	}


	public char [] toCharArray(String s){
		return s.toCharArray() ;
	}
}


