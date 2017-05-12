package study ;

use strict ;
use Test ;


use Inline Config => 
           DIRECTORY => './_Inline_test';

use Inline(
	Java => 'DATA',
) ;

# There once was a bug with importing code twice.
use Inline(
	Java => 'STUDY',
	AUTOSTUDY => 1,
	STUDY => ['t.types'],
	CLASSPATH => '.',
) ;
use Inline(
	Java => 'STUDY',
	AUTOSTUDY => 1,
	STUDY => ['t.types'],
	CLASSPATH => '.',
) ;				   


package toto ;

use Inline(
	Java => 'STUDY',
	AUTOSTUDY => 1,
	STUDY => ['t.types'],
	CLASSPATH => '.',
) ;
use Inline(
	Java => 'STUDY',
	AUTOSTUDY => 1,
	STUDY => ['t.types'],
	CLASSPATH => '.',
	PACKAGE => 'main',
) ;
package study ;

use Inline::Java qw(study_classes) ;



BEGIN {
	plan(tests => 11) ;
}

study_classes([
	't.no_const'
]) ;

my $t = new study::t::types() ;

{
	ok($t->func(), "study") ;
	ok($t->hm()->get("key"), "value") ;
	
	my $nc = new study::t::no_const() ;
	ok($nc->{i}, 5) ;
	
	my $a = new study::study::a8() ;
	ok($a->{i}, 50) ;
	ok($a->truth()) ;
	ok($a->sa()->[1], 'titi') ;
	ok($a->sb()->[0]->get('toto'), 'titi') ;
	ok($a->sb()->[1]->get('error'), undef) ;

	my $toto_t = new toto::t::types() ;
	ok(1) ;
	my $main_t = new t::types() ;
	ok(1) ;
}

ok($t->__get_private()->{proto}->ObjectCount(), 1) ;


__DATA__

__Java__

// Use a public class
package study ;

import java.util.* ;

public class a8 {
	public int i = 50 ;
	
	public a8(){
	}

	public boolean truth(){
		return true ;
	}

	public String [] sa(){
		String a[] = {"toto", "titi"} ;
		return a ;
	}

	public HashMap [] sb(){
		HashMap h1 = new HashMap() ;
		HashMap h2 = new HashMap() ;
		h1.put("toto", "titi") ;
		h2.put("tata", "tete") ;

		HashMap a[] = {h1, h2} ;
		return a ;
	}
}

