#!/usr/bin/perl -w

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'              => 'Matts::Message::Parser',
    'PREREQ_PM'         => { Danga::Socket => 0.52 },
    'VERSION_FROM'      => 'lib/Matts/Message/Parser.pm',
    'ABSTRACT_FROM'     => 'lib/Matts/Message/Parser.pm',
    'AUTHOR'            => 'Matt Sergeant, matt@sergeant.org',
);
