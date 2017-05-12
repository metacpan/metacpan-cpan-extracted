use ExtUtils::MakeMaker;
# Refer to lib/Extutils/MakeMaker.pm for details of 
# how to influence the contents of the Makefile that
# is written.

WriteMakefile( NAME => 'Lib::Module',
	       VERSION_FROM => 'Module.pm',
	       ABSTRACT_FROM => 'Module.pm'
	       );
#WriteMakefile( NAME => 'Lib::ModuleSymbol',
#	       VERSION_FROM => 'ModuleSymbol.pm',
#	       );
#WriteMakefile( NAME => 'Lib::SymbolRef',
#	       VERSION_FROM => 'SymbolRef.pm',
#	       );

	      
