#!/usr/bin/perl -w
use warnings;
use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'File-LogReader',
    AUTHOR       => 'Luke Closs <file-logreader@5thplane.com>',
    VERSION_FROM => 'lib/File/LogReader.pm',
    PREREQ_PM    => {
        'Test::More'   => 0,
        'Digest::SHA1' => 0,
        'YAML'         => 0,
    },
);
