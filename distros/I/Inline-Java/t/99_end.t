use strict ;
use Test ;


BEGIN {
	plan(tests => 1) ;
}


use Inline Config => 
           DIRECTORY => './_Inline_test' ;

use Inline (
	Java => 'STUDY',
) ;

Inline::Java::capture_JVM() ;
ok(Inline::Java::i_am_JVM_owner()) ;

