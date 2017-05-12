use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Geo::Cache',
    VERSION_FROM => 'VERSION',                           # finds $VERSION
    AUTHOR       => 'Rich Bowen (rbowen@rcbowen.com)',
    ABSTRACT     =>
      'Classes for dealing with GeoCaches and the related data files.',
    PREREQ_PM => {
        'Test::More'  => 0,
        'XML::Simple' => 0,
        'Time::CTime' => 0,
    },
);

