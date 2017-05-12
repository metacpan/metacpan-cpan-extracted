use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'File::LinearRaid',
    VERSION_FROM  => 'lib/File/LinearRaid.pm',
    PREREQ_PM     => { Symbol => 0,
                       Carp => 0,
                     },
    ABSTRACT_FROM => 'lib/File/LinearRaid.pm',
    AUTHOR        => 'Mike Rosulek <mike@mikero.com>',
);
