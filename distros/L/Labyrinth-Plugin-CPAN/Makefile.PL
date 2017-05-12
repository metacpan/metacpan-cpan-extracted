#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'Labyrinth::Plugin::CPAN',
    VERSION_FROM        => 'lib/Labyrinth/Plugin/CPAN.pm',
    ABSTRACT            => 'CPAN Testers plugin for the Labyrinth framework',
    NO_META             => 1,
    PREREQ_PM           => {

        # prereqs
        'Class::Accessor::Fast'     => '0',
        'Email::Address'            => '0',
        'JSON'                      => '0',
        'Labyrinth'                 => '5.27',
        'Labyrinth::Plugin::Core'   => '5.18',
        'Sort::Versions'            => '0',
        'WWW::Mechanize'            => '0',

        # build/test prereqs
        'IO::File'                  => '0',
        'Labyrinth::Test::Harness'  => '1.05',
        'Test::Database'            => '0',
        'Test::More'                => '0.70'

    }
);
