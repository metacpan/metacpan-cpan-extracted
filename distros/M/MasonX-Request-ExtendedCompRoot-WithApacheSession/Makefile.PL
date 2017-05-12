use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'MasonX::Request::ExtendedCompRoot::WithApacheSession',
    VERSION_FROM      => 'lib/MasonX/Request/ExtendedCompRoot/WithApacheSession.pm',
    PREREQ_PM         => {'MasonX::Request::ExtendedCompRoot'=>0.03, 'MasonX::Request::WithApacheSession'=>0.24},
);
