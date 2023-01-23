use 5.024000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Error::Show',
    VERSION_FROM      => 'lib/Error/Show.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {
      enum=>0
    }, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/Error/Show.pod', # retrieve abstract from module
    AUTHOR            => 'Ruben Westerberg <drclaw@mac.com>',
    LICENSE           => 'mit',
    META_MERGE        => {
                           'resources' => {
                             'repository' => {
                               'web' => 'https://github.com/drclaw1394/perl-error-show.git',
                               'url' => 'git@github.com:drclaw1394/perl-error-show.git',
                               'type' => 'git',
                             },
                             'homepage' => 'https://github.com/drclaw1394/perl-error-show',
                             'bugtracker' => {
                               'web' => 'https://github.com/drclaw1394/perl-error-show/issues',
                             }
                           },
                           'meta-spec' => {
                             'version' => 2,
                           },
                         },
    #Value must be from legacy list of licenses here
    #https://metacpan.org/pod/Module::Build::API
);
