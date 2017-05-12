#! perl

use ExtUtils::MakeMaker;

my @scripts = qw( midi-dump midi-tweak );

WriteMakefile
(
 PL_FILES      => {},
 INSTALLDIRS   => 'site',
 NAME	       => 'MIDI::Tweaks',
 EXE_FILES     => [ map { "script/$_" } @scripts ],
 PL_FILES      => { 'script/pp.PL'
		       => [ map { "script/$_" } @scripts ],
		  },
 VERSION_FROM  => 'lib/MIDI/Tweaks.pm',
 PREREQ_PM     => {
		   'Test::More' => 0,
		   'MIDI' => '0.80'
		  },
 AUTHOR	       => "Johan Vromans <jv@span.org>",
 ABSTRACT      => "Handy tweaks for MIDI API.",
);
