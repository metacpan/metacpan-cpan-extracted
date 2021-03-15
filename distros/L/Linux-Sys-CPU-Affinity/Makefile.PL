use 5.026001;
use ExtUtils::MakeMaker;
use Config ();

my %Config = %Config::Config;

WriteMakefile(
    NAME              => 'Linux::Sys::CPU::Affinity',
    VERSION_FROM      => 'lib/Linux/Sys/CPU/Affinity.pm',
    PREREQ_PM         => {
        'XSLoader'        =>  0,
        'Test::More'      => '1.302183',
        'Test::Deep'      => '1.130',
        'Test::LeakTrace' => '0.14',
    },
    'META_MERGE'    => {
        'resources' => {
            'bugtracker' => 'https://github.com/KalessinD/perl_linux_sys_cpu_affinity/issues',
            'repository' => 'https://github.com/KalessinD/perl_linux_sys_cpu_affinity',
        },
    },
    ABSTRACT_FROM     => 'lib/Linux/Sys/CPU/Affinity.pm', # retrieve abstract from module
    AUTHOR            => 'Chernenko Dmitriy <cdn@cpan.org>',
    #CCFLAGS           => "-x c++ ${Config{ccflags}}",
    #CONFIGURE_REQUIRES => {"ExtUtils::MakeMaker" => 0,},
    LICENSE           => 'perl',
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
	# Insert -I. if you add *.h files later:
    INC               => '', # e.g., '-I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
