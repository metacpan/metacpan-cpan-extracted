#!/usr/bin/perl

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME		=> 'Hardware::1Wire::HA7Net',
    VERSION_FROM	=> 'lib/Hardware/1Wire/HA7Net.pm',
    PREREQ_PM		=> { 'LWP::UserAgent' => 0 },
);
