
use lib "../..";
use PDL::Core::Dev;

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
$Verbose = 1;

WriteMakefile(
    'NAME'				 => 'PDL::Meschach',
		'DISTNAME' 		 => 'Meschach',
    'VERSION_FROM' => 'Meschach.pm', 
		'OBJECT'			 => 'mespdl.o p_funcs.o Meschach.o',
    'PM'					 => {'Meschach.pm' => '$(INST_LIBDIR)/Meschach.pm'},
    'LIBS'				 => ['-Lmeschach-1.2 -lmes','-lm'],
		'TYPEMAPS'     => [PDL_TYPEMAP], 
    'DEFINE'			 => '',
    'INC'				   => '-Imeschach-1.2 '.PDL_INCLUDE,
		'NORECURS'     => 'true',
    'clean'        => {'FILES'  => 'mespdl.o p_funcs.o Meschach.o'},
    'dist'         => { COMPRESS => "gzip -9f" },
);

