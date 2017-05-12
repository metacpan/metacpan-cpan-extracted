#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'Labyrinth::Plugin::Core',
    VERSION_FROM        => 'lib/Labyrinth/Plugin/Core.pm',
    ABSTRACT            => 'Labyrinth Website Management Framework Core Plugins',
    NO_META             => 1,
    PREREQ_PM           => {

        # Labyrinth packages
        'Labyrinth'             => '5.27',

        # prereqs
        'Clone'                 => '0',
        'Config::IniFiles'      => '0',
        'Data::Pageset'         => '0',
        'Digest::MD5'           => '0',
        'File::Copy'            => '0',
        'File::Basename'        => '0',
        'Image::Size'           => '0',
        'Time::Local'           => '0',
        'URI::Escape'           => '0',

        # build/test prereqs
        'IO::File'              => '0',
        'Test::More'            => '0.70'

    }
);
