package Inline::Java::JNI ;
@Inline::Java::JNI::ISA = qw(DynaLoader) ;


use strict ;

$Inline::Java::JNI::VERSION = '0.53' ;

use DynaLoader ;
use Carp ;
use File::Basename ;


if ($^O eq 'solaris'){
	load_lib('-lthread') ;
}


sub load_lib {
	my $l = shift ;
	my $lib = (DynaLoader::dl_findfile($l))[0] ;	
	
    if ((! $lib)||(! defined(DynaLoader::dl_load_file($lib, 0x01)))){
		carp("Couldn't find or load $l.") ;
	}
}


# A place to attach the Inline object that is currently in Java land
$Inline::Java::JNI::INLINE_HOOK = undef ;


eval {
	Inline::Java::JNI->bootstrap($Inline::Java::JNI::VERSION) ;
} ;
if ($@){
	croak "Can't load JNI module. Did you build it at install time?\nError: $@" ;
}


1 ;
