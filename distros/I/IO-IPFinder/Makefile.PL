use 5.026001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'IO::IPFinder',
    VERSION_FROM      => 'lib/IO/IPFinder.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/IO/IPFinder.pm', # retrieve abstract from module
    VERSION_FROM      => 'lib/IO/IPFinder.pm', # retrieve VERSION  from module
    AUTHOR            => 'Mohamed Ben rebia <mohamed@ipfinder.io>',
    LICENSE           => 'apache_2_0',
    PREREQ_PM => {
        'LWP::UserAgent'          => '0',
        'JSON'                    => '0',

    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
        'Test::Exception' => '0',
    },
    dist              => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'IO-IPFinder-*' },
    #Value must be from legacy list of licenses here
    #http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
);
