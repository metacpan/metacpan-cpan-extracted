use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	'NAME'		=> 'GD::Graph3d',
	'VERSION_FROM'	=> 'lib/GD/Graph3d.pm', # finds $VERSION

	($] >= 5.005 ?
		('ABSTRACT'		=> 'Creates 3D charts with GD::Graph and GD.',
		 'AUTHOR'		=> 'Jeremy Wadsack <dgsupport@wadsack-allen.com>',
		) : ()
	),

	'PREREQ_PM'			=> { 
		'GD' => '1.18', 
		'GD::Graph' => '1.30',
		'GD::Text::Align' => undef,
	},

);


print <<END;

The test suite for GD::Graph3d is very basic. It makes sure that 
graphs objects can be contructed and plotted. If you want to verify 
that the plots are accurate, you should run the 'visual-test.pl' 
script in the t/ directory. To do this you may need to look at 
images in a web browser or graphics program and visually verify 
that they are substantially similar.

Otherwise continue on with the standard 'make', 'make test', 
'make install' procedure.

END

