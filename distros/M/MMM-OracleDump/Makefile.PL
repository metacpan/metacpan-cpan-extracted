use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

sub MY::post_initialize {
	return qq{
export
SCRIPTDIR=scripts
	
 };	
}

sub MY::postamble {
	return qq{
\$(EXE_FILES) ::
\t\@echo "Copying \$(SCRIPTDIR)/\$@.pl to \$@ with macro expansion"
\t\@perl -spe 's/%%([A-Z_0-9]+)%%/\$\$ENV{\$\$1}/g' \$(SCRIPTDIR)/\$@.pl > \$@;	
	};	
}

WriteMakefile(
    'NAME'	=> 'MMM::OracleDump',
    'VERSION_FROM' => 'OracleDump.pm', # finds $VERSION
    'EXE_FILES'   => [ 'oracle_dump' ], 	 
    clean => {
    	FILES =>  'oracle_dump'
	}
);





