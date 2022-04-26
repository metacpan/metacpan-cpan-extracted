use 5.026001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Getopt::optparse',
    VERSION_FROM      => 'lib/Getopt/optparse.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {
        # run prereqs
        'Scalar::Util' => 0,
        # build/test prereqs
        'Test::More'        => 0,
    },
    ABSTRACT_FROM     => 'lib/Getopt/optparse.pm', # retrieve abstract from module
    AUTHOR            => 'Matt Hersant <matt_hersant@yahoo.com>',
    #LICENSE           => 'perl',
    #Value must be from legacy list of licenses here
    #http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
);
