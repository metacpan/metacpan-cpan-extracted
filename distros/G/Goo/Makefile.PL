use strict;
use warnings;
use ExtUtils::MakeMaker;

use 5.006;                   # this module requires Perl 5.6.0

WriteMakefile(
    NAME                => 'Goo',
    AUTHOR              => 'Nigel Hamilton <nigel@trexy.com>',
    VERSION_FROM        => 'lib/Goo.pm',
    PL_FILES            => {},
    EXE_FILES           => [ 'bin/goo.pl', 'bin/goo' ],
    PREREQ_PM => {
        'CGI'               => 0,
        'Config::Auto'      => 0,
        'Config::Tiny'      => 0,
        'DBD::SQLite'       => 0,
        'Devel::Symdump'    => 0,
        'File::Find'        => 0,
        'File::Grep'        => 0,
        'File::NCopy'       => 0,
        'LWP::ConnCache'    => 0,
        'LWP::UserAgent'    => 0,
        'Perl::Tidy'        => 0,
        'Pod::Coverage'     => 0,
        'Term::ANSIColor'   => 0,
        'Term::Complete'    => 0,
        'Term::ProgressBar' => 0,
        'Term::ReadKey'     => 0,
        'Test::More'        => 0,
        'Test::Pod'         => 0,
        'Test::Pod::Coverage' => 0,
        'Text::FormatTable' => 0,
        'Time::HiRes'       => 0,
    },
    dist     => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean    => { FILES => 'Goo-*' },
);
