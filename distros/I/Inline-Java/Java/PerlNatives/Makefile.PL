use ExtUtils::MakeMaker ;

use strict ;
require "../Portable.pm" ;


WriteMakefile(
	NAME => 'Inline::Java::PerlNatives',
	VERSION_FROM => 'PerlNatives.pm',
	INC => join(' ', @main::I),
	LIBS => [join(' ', @main::L) . " -ljvm"],
	dynamic_lib => Inline::Java::Portable::portable("dynamic_lib"),
	# CCFLAGS => '-D_REENTRANT',
    clean => {FILES => "_Inline_test"},
) ;

