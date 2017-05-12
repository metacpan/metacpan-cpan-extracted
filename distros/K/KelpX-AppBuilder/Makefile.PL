use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'KelpX::AppBuilder',
    VERSION_FROM    => 'lib/KelpX/AppBuilder.pm',
    ABSTRACT        => 'Create reusable apps with Kelp',
    CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' },
    DISTNAME        => 'KelpX-AppBuilder',
    TEST_REQUIRES   => {
        'Test::More' => 0,
        'Kelp::Test' => 0,
    },

    PREREQ_PM       => {
        'Kelp'      => 0,
        'Import::Into' => 0,
        'Module::Find' => 0,
        'Kelp::Module::Template::Toolkit' => 0,
        'File::ShareDir' => 0,
        'Plack::Middleware::Static' => 0,
    },        
);
