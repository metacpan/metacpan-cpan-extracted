use 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker 6.3002;

WriteMakefile(
    NAME           => 'File::Flock::Tiny',
    AUTHOR         => q{Pavel Shaydo <zwon@cpan.org>},
    VERSION_FROM   => 'lib/File/Flock/Tiny.pm',
    ABSTRACT_FROM  => 'lib/File/Flock/Tiny.pm',
    LICENSE        => 'perl',
    PL_FILES       => {},
    BUILD_REQUIRES => {
        'Test::More'  => 0.94,
        'Path::Class' => 0,
        'File::Slurp' => 9999.14,
    },
    PREREQ_PM => {
        'Test::More' => 0.94,
        'parent'     => 0,
    },
    dist       => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean      => { FILES    => '[% st.dist_dir_name %]-*' },
    META_MERGE => {
        no_index  => { file => 'README.pod' },
        resources => {
            homepage   => 'https://github.com/trinitum/perl-File-Flock-Tiny',
            bugtracker => 'https://github.com/trinitum/perl-File-Flock-Tiny/issues',
            repository => 'git://github.com/trinitum/perl-File-Flock-Tiny',
            license    => 'http://dev.perl.org/licenses/',
        },
        keywords => [ 'flock', 'pid', 'lock', 'file', ],
    },
);
