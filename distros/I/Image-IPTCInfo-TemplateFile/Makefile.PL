use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Image::IPTCInfo::TemplateFile',
    'VERSION_FROM'	=> 'TemplateFile.pm', # finds $VERSION
    'PREREQ_PM'		=> {
		Image::IPTCInfo => 1.6,
	}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'TemplateFile.pm', # retrieve abstract from module
       AUTHOR     => 'lgoddard -at- cpan -dot- org>') : ()),
);
