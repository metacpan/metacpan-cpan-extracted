use 5.026001;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'List::Helpers::XS',
    VERSION_FROM      => 'lib/List/Helpers/XS.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {
        'XSLoader'        =>  0,
        'Test::More'      => '1.302183',
        'Test::LeakTrace' => '0.14',
    },
    'META_MERGE'    => {
        'resources' => {
            'bugtracker' => 'https://github.com/KalessinD/perl_linux_sys_cpu_affinity/issues',
            'repository' => 'https://github.com/KalessinD/perl_linux_sys_cpu_affinity',
        },
    },
    ABSTRACT_FROM     => 'lib/List/Helpers/XS.pm', # retrieve abstract from module
    AUTHOR            => 'Chernenko Dmitriy <cnd@cpan.org>',
    LICENSE           => 'perl',
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '', # e.g., '-I/usr/include/other'
);
