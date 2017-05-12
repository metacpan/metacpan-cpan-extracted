# Based on earlier h2xs output and
# output from Module::Build::Compat version 0.03
use strict;
use File::Spec;
my $script = File::Spec->catfile( 'script',
		    $^O =~ /win/i 
			? 'file-rename' : 'rename' );

use ExtUtils::MakeMaker;
WriteMakefile(
          NAME		=> 'File::Rename',
          VERSION_FROM	=> 'lib/File/Rename.pm',
          INSTALLDIRS	=> 'site',
          PREREQ_PM	=> {
		'Getopt::Long'	=> 0,	# recommend 2.24 for posix_default
		'File::Temp'	=> 0,	# for testing
		'Test::More'	=> 0,	# for testing(!)
	  },
          EXE_FILES	=> [ $script ],
	  PL_FILES	=> { 'rename.PL' => $script },
	  ABSTRACT_FROM	=> 'lib/File/Rename.pm',
					# retrieve abstract from module
	  AUTHOR     	=> 'Robin Barker <RMBarker@cpan.org>',
);
