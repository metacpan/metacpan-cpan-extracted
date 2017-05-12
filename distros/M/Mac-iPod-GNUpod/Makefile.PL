#!/usr/bin/perl

use strict;
use warnings;
use ExtUtils::MakeMaker qw/WriteMakefile/;

WriteMakefile(
    NAME =>             'Mac::iPod::GNUpod',
    ABSTRACT_FROM =>    'GNUpod.pm',
    VERSION_FROM =>     'GNUpod.pm',
    PREREQ_PM =>        {
        'MP3::Info' =>        1.02,
        'MP4::Info' =>        1.07,
        'XML::Parser' =>      2.33,
        'File::Copy' =>       2.05,
        'File::Spec' =>       0.85,
        'File::Spec::Mac' =>  1.4,
        'Audio::Wav' =>       0.04,
        'Unicode::String' =>  2.07
                        }
);
