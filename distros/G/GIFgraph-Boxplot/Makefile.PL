# This -*- perl -*- script makes the Makefile
# $Id: Makefile.PL,v 1.0 1999/08/27 17:30:15 nigel $
 
#--- Distribution section ---
 
BEGIN { require 5.001 }
 
use ExtUtils::MakeMaker;
 
my @clean = qw(*% *.html *.b[ac]k *.old .[A-z]* tags);
push @clean, map { "*/$_" } @clean;
 
WriteMakefile(
        'NAME'      		=> 'GIFgraph::boxplot',
        'VERSION_FROM'		=> 'boxplot.pm',	#finds $VERSION

		($] >= 5.005 ?
			('ABSTRACT'		=> 'Produces GIF box and whisker graphs',
			 'AUTHOR'		=> 'Nigel Wright (nwright@hmc.edu)',
			) : ()
		),

		'PREREQ_PM'			=> { 'GD' => 1.14,
							'GIFgraph' => 1.10,
							'Statistics::Descriptive' => 2.4
		},
 
        'dist'    			=> {
			'COMPRESS' 		=> 'gzip -9f',
			'SUFFIX'   		=> 'gz', 
		},
 
        'clean'   => { 'FILES' => join(" ", @clean), },
);

