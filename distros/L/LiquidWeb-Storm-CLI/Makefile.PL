use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'LiquidWeb::Storm::CLI',
    VERSION_FROM => 'lib/LiquidWeb/Storm/CLI.pm', # finds $VERSION
    EXE_FILES    => ['bin/lw-cli'],
    INSTALLBIN   => '/usr/bin',
    INSTALLSCRIPT => '/usr/bin', 
    INSTALLDIRS  => 'perl',  
    PREREQ_PM    => {
		'Getopt::Long'     => 0,
		'HTTP::Request'    => 0, 
		'LWP::UserAgent'   => 0,
		'MIME::Base64'     => 0, 
		'Text::ASCIITable' => '0.20', 
		JSON => 0, 
	}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/LiquidWeb/Storm/CLI.pm', # retrieve abstract from module
       AUTHOR         => 'Matthew Terry, E<lt><mterry@liquidweb.com>E<gt>') : ()),
);
