use 5.6.0;
use strict;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

use File::Find;

find( \&filecheck, "." );

sub filecheck {
    unlink if /~$/;  # Remove any emacs backup files
    die "Aborting: Swapfile $_ found" if /\.swp$/;
}

&WriteMakefile(
	'NAME'		=> 'MARC::Descriptions',
	'DISTNAME'	=> 'MARC-Descriptions',
	'VERSION_FROM'	=> 'lib/MARC/Descriptions.pm', # finds $VERSION
	'ABSTRACT_FROM' => 'lib/MARC/Descriptions.pm',
	'PMLIBDIRS'	=> [ qw( lib/ ) ],
	'AUTHOR'	=> 'David Christensen <DChristensenSPAMLESS@westman.wave.ca>',
	'PREREQ_PM'	=> {
			   'Test::More' => 0,
			   'Clone' => 0,
			   'Clone::Any' => 0,
			   },
#	'ABSTRACT_FROM' => 'lib/Foo.pm',
	'EXE_FILES'	=> [ qw( ) 
			     ],
	'dist'		=> {
			   COMPRESS => 'gzip -9f',
			   SUFFIX => 'gz',
			   },
	'depend'	=> {
			   Makefile => '$(VERSION_FROM)'
			   },
);
