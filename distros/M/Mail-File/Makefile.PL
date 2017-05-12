#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'Mail::File',
    VERSION_FROM        => 'lib/Mail/File.pm',
    ABSTRACT            => 'Write mail messages to a plain text file',
    NO_META             => 1,
    PREREQ_PM           => {

        # runtime prereqs
		'File::Temp'        => 0,
		'File::Path'        => 0,
		'File::Basename'    => 0,
		'Time::Piece'       => 0,

        # build/test prereqs
        'IO::File'          => '0',
        'Test::More'        => '0.70',

    }
);
