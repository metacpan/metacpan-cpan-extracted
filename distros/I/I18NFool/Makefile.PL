use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'I18NFool',
    'VERSION_FROM'	=> 'lib/I18NFool.pm', # finds $VERSION
    'EXE_FILES'         => [ 'bin/i18nfool-extract', 'bin/i18nfool-build', 'bin/i18nfool-update' ],
    'PREREQ_PM'		=> {
	'Test::Harness'	    => '2.00',
	'Scalar::Util'      => '1.07',
	'MKDoc::XML'        => '0.72',
        'Locale::PO'        => '0.11',
        'Getopt::Long'      => '2.30',
    },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/I18NFool.pm', # retrieve abstract from module
       AUTHOR     => 'Jean-Michel Hiver') : ()),
);


1;


package MY;

sub postamble {
    return <<EOF;
cover ::
	\$(RM_RF) cover_db
	PERL5OPT=-MDevel::Cover \$(MAKE) test || true
	cover -report html cover_db > /dev/null

EOF

}


1;
