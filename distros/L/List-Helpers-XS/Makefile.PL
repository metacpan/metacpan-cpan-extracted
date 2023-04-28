package main;

use 5.026001;
use ExtUtils::MakeMaker;
use Config ();

my %Config = %Config::Config;

WriteMakefile(
    NAME              => 'List::Helpers::XS',
    VERSION_FROM      => 'lib/List/Helpers/XS.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {
        'XSLoader'        =>  0,
        'Test::More'      => '1.302183',
        'Test::LeakTrace' => '0.14',
        'Config'          => 0,
    },
    'META_MERGE'    => {
        'resources' => {
            'bugtracker' => 'https://github.com/KalessinD/perl_list_helpers_xs/issues',
            'repository' => 'https://github.com/KalessinD/perl_list_helpers_xs',
        },
    },
    CC => 'c++',
    LD => 'c++',
    CCFLAGS   => "-O3 -std=c++17 -msse2 -msse4.2 ${Config{ccflags}}",
    LDDLFLAGS => "-O3 -std=c++17 -msse2 -msse4.2 ${Config{lddlflags}}",
    ABSTRACT_FROM     => 'lib/List/Helpers/XS.pm', # retrieve abstract from module
    AUTHOR            => 'Chernenko Dmitriy <cnd@cpan.org>',
    LICENSE           => 'perl',
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '', # e.g., '-I/usr/include/other'
);

1;
__END__
