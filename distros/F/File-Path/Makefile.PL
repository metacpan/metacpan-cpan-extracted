# generate Makefile for building File::Path
#
# Copyright (C) 2007 David Landgren
# Copyright (C) 2015 Richard Elberger, James Keenan

use strict;
use ExtUtils::MakeMaker;

#eval "use ExtUtils::MakeMaker::Coverage";
#$@ or print "Adding testcover target\n";

WriteMakefile(
    NAME          => 'File::Path',
    VERSION_FROM  => 'lib/File/Path.pm',
    ABSTRACT_FROM => 'lib/File/Path.pm',
    AUTHOR        => 'Richard Elberger',
    INSTALLDIRS   => ($] < 5.011 ? 'perl' : 'site'),
    PREREQ_PM => {
        'Carp'           => 0,
        'Cwd'            => 0,
        'File::Basename' => 0,
        'File::Spec'     => 0,
        'SelectSaver'    => 0,
        ( eval { $] < 5.006 } ? ( 'Symbol' => 0 ) : () ),
    },
    clean => {
        FILES => 'cover_db test-*',
    },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? ( META_MERGE => {
      'meta-spec' => { version => 2 },
      resources => {
        repository  => {
          url  => 'https://github.com/rpcme/File-Path.git',
          web  => 'https://github.com/rpcme/File-Path',
          type => 'git',
        },
      },
      license => 'perl',
    }) : () ),
);
