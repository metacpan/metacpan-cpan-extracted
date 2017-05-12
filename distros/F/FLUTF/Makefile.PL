#!/usr/bin/perl
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME=>'Games::Freelancer::UTF',
	VERSION_FROM=>'lib/Games/Freelancer/UTF.pm',
	PREREQ_PM=>{
		 "Tie::InsertOrderHash"=>0,
		 "Exporter"=>0,
		 "Carp"=>0
	}
);
