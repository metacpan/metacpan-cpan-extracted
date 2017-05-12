package MegaDistro::DebMaker::Config;

use strict;
use warnings;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(%buildtree);
our @EXPORT_OK = qw( %metadata %section build_pre );
our %EXPORT_TAGS;
$EXPORT_TAGS{'default'} = \@EXPORT;
$EXPORT_TAGS{'build'} = \@EXPORT_OK;

use File::Path;
use File::Spec::Functions qw(:ALL);

use lib '../MegaDistro';

use MegaDistro;
use MegaDistro::Config;


#
# Package-specific configurables
#
# the package metadata (headers)
our %metadata = (
		  # the package Name
		  'name'	  =>	'megadistro',	
		 
		  # the package Version
		  'version'	  =>	$MegaDistro::VERSION,		
		 
		  # the package Release number
		  'release'	  =>	'5',		
		 
		  # the package Section
		  'section'	  =>	'libs',
		 
		  # the package Priority
		  'priority'	  =>	'optional',	
		 
		  # the package Dependencies
		  'depends'	  =>	'perl (>= 5.6.1)',
		 
		  # the package Suggestions
		  'suggests'	  =>	'perl (>= 5.8.5)',
		 
		  # the package Replaces
		  'replaces'	  =>	'megadistro (<< ' . $MegaDistro::VERSION . ')',
		  
		  # the package Conflicts
		  'conflicts'     =>    'megadistro (<< ' . $MegaDistro::VERSION . ')',
		 
		  # the package Maintainer
		  'maintainer'    =>    'David Buchman <dbuchman@cpan.org>',
		  
		  # the package Description (short)
		  'description'   =>    'A packaged bundle of pre-compiled perl modules.',
		 					
	        );

# hash to contain various sections
our %section;

# the Description section (long)
$section{'description'} =  [
		    	     'The MegaDistro is a distributable binary package,',
		    	     'which contains a selection of pre-compiled perl modules.',
		    	     '.',
		    	     'Simply feed it a list of modules,',
		    	     'configure manually if necessary,',
		    	     'and crank out a package!',
		  	   ];


# hash to contain the various directories needed for building the rpm, on the system
our %buildtree;

sub _init_globals {
	# Package directory (name)
	$buildtree{'PACKAGE'}   = 'debian';

	# SOURCES directory
	$buildtree{'ROOT'}      = catdir($Conf{'rootdir'}, $buildtree{'PACKAGE'});

	# BUILD directory
	$buildtree{'CONTROL'}   = catdir($buildtree{'ROOT'}, 'DEBIAN');

	# RPM directory
	$buildtree{'BUILDROOT'} = $buildtree{'ROOT'};
}

&_init_globals;

#
# Preparation
#
sub build_pre {
	if ( $args{'trace'} ) {
		print 'MegaDistro::DebMaker::Config : Executing sub-routine: build_pre' . "\n";
	}
	
	mkpath $buildtree{'ROOT'}      if ! -d $buildtree{'ROOT'};
	mkpath $buildtree{'CONTROL'}   if ! -d $buildtree{'CONTROL'};
	mkpath $buildtree{'BUILDROOT'} if ! -d $buildtree{'BUILDROOT'};
}

1;
