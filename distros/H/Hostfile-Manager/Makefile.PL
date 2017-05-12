use strict;
use warnings;
use ExtUtils::MakeMaker;

BEGIN { require 5.006; }

my %conf = (
	NAME => 'Hostfile::Manager',
	VERSION_FROM => 'lib/Hostfile/Manager.pm',
	EXE_FILES => ['bin/hostfiles'],
	PREREQ_PM => {
		'File::Basename' => 0,
		'File::Find' => 0,
		'File::Slurp' => 0,
		'Getopt::Long' => 0,
		'Moose' => 0,
		'Pod::Usage' => 0,
		'Term::Clui' => 0,
	},
	BUILD_REQUIRES => {
		'Test::Class' => 0,
		'Test::Deep' => 0,
		'Test::Most' => 0,
		'Test::NoWarnings' => 0,
	},
	AUTHOR => 'Anthony J. Mirabella',
	ABSTRACT => 'Manage a hostfile by composing multiple fragments into a whole.',
	LICENSE => 'perl',
	META_MERGE => {
		resources => {
			repository => 'git://github.com/Aneurysm9/hostfile_manager.git',
			homepage => 'https://github.com/Aneurysm9/hostfile_manager',
		},
	},
);

my $eumm_version =  do {
    no warnings 'numeric';
    eval $ExtUtils::MakeMaker::VERSION;
};

delete $conf{META_MERGE} if $eumm_version < 6.46;

$conf{PREREQ_PM} = {
    %{ $conf{PREREQ_PM} || {} }, %{ delete $conf{BUILD_REQUIRES} },
} if ($conf{BUILD_REQUIRES} and $eumm_version < 6.5503);

WriteMakefile(%conf);
