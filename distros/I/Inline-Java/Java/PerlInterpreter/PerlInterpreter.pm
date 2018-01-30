package Inline::Java::PerlInterpreter ;

use strict ;
use Inline::Java ;

$Inline::Java::PerlInterpreter::VERSION = '0.52' ;


use Inline (
	Java => 'STUDY',
	STUDY => [],
	AUTOSTUDY => 1,
	EMBEDDED_JNI => 1,
	NAME => 'Inline::Java::PerlInterpreter',
) ;


1 ;
