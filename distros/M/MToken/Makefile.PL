#!/usr/bin/perl -w
use strict;
use ExtUtils::MakeMaker;

my $build_requires = {
        'ExtUtils::MakeMaker'   => 6.60,
        'Test::More'            => 0.94,
    };

my $prereq_pm = {
        'Archive::Tar'          => 1.80, # perl-Archive-Tar
        'CTK'                   => 2.03, # perl-CTK (libctk-perl)
        'DBD::SQLite'           => 1.00, # perl-DBD-SQLite (libdbd-sqlite3-perl)
        'Digest::MD5'           => 2.52, # perl-Digest-MD5
        'Digest::SHA'           => 4.00, # perl-Digest-SHA
        'Encode::Locale'        => 1.00, # perl-Encode-Locale
        'File::HomeDir'         => 1.00, # perl-File-HomeDir
        'File::Spec'            => 3.40,
        'List::Util'            => 1.50, # (libscalar-list-utils-perl)
        'Mojolicious'           => 7.94, # perl-Mojolicious (libmojolicious-perl)
        'Text::SimpleTable'     => 2.00, # (libtext-simpletable-perl)
        'Try::Tiny'             => 0.10, # (libtry-tiny-perl)
        'URI'                   => 1.70, # (liburi-perl)
    };

my $exefiles = [qw(
        bin/mtoken
    )];

WriteMakefile(
    'NAME'                  => 'MToken',
    'MIN_PERL_VERSION'      => 5.016001,
    'VERSION_FROM'          => 'lib/MToken.pm',
    'ABSTRACT_FROM'         => 'lib/MToken.pm',
    'EXE_FILES'             => $exefiles,
    'BUILD_REQUIRES'        => $build_requires,
    'PREREQ_PM'             => $prereq_pm,
    'LICENSE'               => 'perl',
    'AUTHOR'                => 'Serz Minus (Sergey Lepenkov) <abalama@cpan.org>',
    'META_MERGE' => { 'meta-spec' => { version => 2 },
        recommends => {
            'Data::Dumper'  => 0,
        },
        resources => {
            homepage        => 'https://www.serzik.com',
            repository      => 'http://svn.serzik.com/MToken/trunk/',
            license         => 'https://dev.perl.org/licenses',
        },
    },
    clean => {
            FILES => '*.tmp',
        },

);
