use v5.10.0;

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Dummy::Repo',
    VERSION_FROM => 'lib/Dummy/Repo.pm', # finds \$VERSION
    AUTHOR       => 'James E Keenan (jkeenan@cpan.org)',
    ABSTRACT     => 'A repo solely for testing other git repos',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                    },
);
