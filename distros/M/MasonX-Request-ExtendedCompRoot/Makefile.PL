use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'MasonX::Request::ExtendedCompRoot',
    VERSION_FROM      => 'lib/MasonX/Request/ExtendedCompRoot.pm',
    PREREQ_PM         => {'HTML::Mason'=>1.37},
);
