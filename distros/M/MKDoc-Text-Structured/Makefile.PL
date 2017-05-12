use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'MKDoc::Text::Structured',
    'VERSION_FROM'      => 'lib/MKDoc/Text/Structured.pm', # finds $VERSION
    'EXE_FILES'         => [ 'bin/text2xhtml' ],
    'PREREQ_PM'		=> {
        'Test::More'    => '0.47',
        'Scalar::Util'  => '1.07',
        'URI::Find'	=> '0.13',
        'Getopt::Declare' => '',
    },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/MKDoc/Text/Structured.pm', # retrieve abstract from module
       AUTHOR     => 'Jean-Michel Hiver') : ()),
);


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
