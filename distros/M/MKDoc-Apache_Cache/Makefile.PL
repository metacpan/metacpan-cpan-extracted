use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'MKDoc::Apache_Cache',
    'VERSION_FROM'	=> 'lib/MKDoc/Apache_Cache.pm', # finds $VERSION
    'PREREQ_PM'         => {
        'Apache'              => '1.20',
        'MKDoc::Control_List' => '0.1',
        'Cache::Cache'        => '1.01',
        'Test::More'          => '0.47',
        'HTTP::Date'          => '0.1',
	'Compress::Zlib'      => '1.33',
	'Digest::MD5'         => '2.33',
    },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/MKDoc/Apache_Cache.pm', # retrieve abstract from module
       AUTHOR     => 'Jean-Michel Hiver <info@mkdoc.com>') : ()),
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
