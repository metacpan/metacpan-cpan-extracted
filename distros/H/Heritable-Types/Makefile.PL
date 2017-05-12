use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Heritable::Types',
    VERSION_FROM => 'lib/Heritable/Types.pm', # finds $VERSION
    AUTHOR       => 'Piers Cawley <pdcawley@bofh.org.uk>',
    ABSTRACT     => '',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                     'Test::More' => undef,
                     'Test::Exception' => undef,
                    },
);
