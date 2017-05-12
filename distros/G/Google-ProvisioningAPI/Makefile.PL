use 5.008005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Google::ProvisioningAPI',
    VERSION_FROM      => 'lib/Google/ProvisioningAPI.pm', # finds $VERSION
    PREREQ_PM         => { 	'Carp' => 0,
							'LWP::UserAgent' => 0,
							'HTTP::Request' => 0,
							'Encode' => 0,
							'XML::Simple' => 0
						}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Google/ProvisioningAPI.pm', # retrieve abstract from module
       AUTHOR         => 'Johan Reinalda <johan@reinalda.net>') : ()),
);
