use ExtUtils::MakeMaker::CPANfile;

WriteMakefile(
    'NAME'          => 'Log::Log4perl::OpenTracing',
    'VERSION_FROM'  => 'lib/Log/Log4perl/OpenTracing.pm',
    'LICENSE'       => 'perl',
    test            => {
        TESTS       => 't/*.t',
    },
);
