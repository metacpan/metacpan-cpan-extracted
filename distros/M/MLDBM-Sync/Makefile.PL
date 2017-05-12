#!/usr/local/bin/perl

use ExtUtils::MakeMaker;

&WriteMakefile( 
		NAME => "MLDBM::Sync", 
		VERSION_FROM => 'Sync.pm', 
		PREREQ_PM => { 
		    MLDBM => 1,
		},
		);
