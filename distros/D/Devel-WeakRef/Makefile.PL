#!/sig/local/bin/perl5 -w

use ExtUtils::MakeMaker;

WriteMakefile(
# $Format: " VERSION => '$DevelWeakRefRelease$',"$
 VERSION => '0.003',
              NAME => 'Devel::WeakRef',
	      PREREQ_PM => {
			    Test::Helper => 0.002
			   },
#	      EXE_FILES => []
);
