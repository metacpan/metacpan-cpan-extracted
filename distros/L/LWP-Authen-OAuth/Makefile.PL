use 5.006000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'LWP::Authen::OAuth',
    VERSION_FROM      => 'lib/LWP/Authen/OAuth.pm', # finds $VERSION
    PREREQ_PM         => {
				'LWP::UserAgent' => 0.0,
				'Digest::SHA' => 0.0,
				'URI' => 0.0,
				'URI::Escape' => 0.0,
				'MIME::Base64' => 0.0,
				'Test::More' => 0.0,
			}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/LWP/Authen/OAuth.pm', # retrieve abstract from module
       AUTHOR         => 'Timothy D Brody <tdb2@ecs.soton.ac.uk>') : ()),
	dist              => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	META_MERGE => {
		resources         => {
			url     =>  'git://github.com/timbrody/lwp-authen-oauth.git',
			web     =>  'https://github.com/timbrody/lwp-authen-oauth',
			type    =>  'git',
		},
	}
);
