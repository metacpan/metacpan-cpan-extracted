# generate Makefile for building File::Path
#
# Copyright (C) 2007 David Landgren
# Copyright (C) 2015 Richard Elberger, James Keenan

use strict;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME          => 'File::Path',
    VERSION_FROM  => 'lib/File/Path.pm',
    ABSTRACT_FROM => 'lib/File/Path.pm',
    INSTALLDIRS   => ($] < 5.011 ? 'perl' : 'site'),
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    PREREQ_PM    => {
        'Cwd'            => 0,
        'Exporter'       => 0,
        'File::Basename' => 0,
        'File::Spec'     => 0,
        ( eval { $] < 5.006 } ? ( 'Symbol' => 0 ) : () ),
    },
    TEST_REQUIRES => {
        'Carp'                  => 0,
        'Config'                => 0,
        'Errno'                 => 0,
        'Fcntl'                 => 0,
        'File::Spec::Functions' => 0,
        'SelectSaver'           => 0,
        'Test::Simple'          => 0.44,
    },
    clean => {
        FILES => 'cover_db test-*',
    },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? ( META_MERGE => {
      'meta-spec' => { version => 2 },
      resources => {
        repository  => {
          url  => 'https://github.com/jkeenan/File-Path.git',
          web  => 'https://github.com/jkeenan/File-Path',
          type => 'git',
        },
      },
      license => 'perl',
    }) : () ),
);
if ($^O eq 'MSWin32') {
    $WriteMakefileArgs{TEST_REQUIRES}{'Win32'} = 0;
}

my %FallbackPrereqs = (
    %{$WriteMakefileArgs{PREREQ_PM}},
    %{$WriteMakefileArgs{TEST_REQUIRES}},
);

unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
    delete $WriteMakefileArgs{TEST_REQUIRES};
    delete $WriteMakefileArgs{BUILD_REQUIRES};
    $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);

