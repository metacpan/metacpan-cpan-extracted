#!perl

use strict;
use ExtUtils::MakeMaker;

# Libs required to build PLplot applications
my $pllibs = '-L/usr/local/lib -lplplotd -L/usr/X11R6/lib -lX11';

# Include files
my $plinc = '-I/usr/local/include';

# Write the makefile
WriteMakefile(
	      NAME => 'Graphics::PLplot',
	      VERSION_FROM => 'PLplot.pm',
	      LIBS => [ $pllibs ],
	      INC  => "$plinc",
	      OBJECT  => 'PLplot.o arrays.o',
	      'dist'      => {'COMPRESS'=>'gzip -9f', 'SUFFIX' => 'gz',
			      'ZIP'=>'/usr/bin/zip','ZIPFLAGS'=>'-rl'},
	      ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
	       (ABSTRACT_FROM => 'PLplot.pm',
		AUTHOR     => 'Tim Jenness <t.jenness@jach.hawaii.edu>') : ()),
);
