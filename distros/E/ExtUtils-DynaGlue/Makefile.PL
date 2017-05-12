use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'ExtUtils::DynaGlue',
#    'VERSION_FROM' => 'DynaGlue.pm', # finds $VERSION
    'VERSION' => '1.00a', 	      
    'dist'    => {
	COMPRESS=> 'gzip -9f', SUFFIX=>'gz', 
	POSTOP => 'mv $(DISTNAME)-$(VERSION).tar.gz ../'},
);
