use ExtUtils::MakeMaker;

WriteMakefile(
	      'NAME'	=> 'Image::Shoehorn',
	      ($[ >= 5.005) ?
	      (AUTHOR   => 'Aaron Straup Cope (cpan@aaronland.net)',
	       ABSTRACT => '') : (),
	      'VERSION_FROM' => 'lib/Image/Shoehorn.pm',
	      'PREREQ_PM'    => {
				 Image::Magick  => '5.44',
				 Error          => '0',
				 File::Basename => '0',
				 File::MMagic   => '1.16',
				 Carp           => '0',

				 # For t/*.t
				 Test::More     => '0',  
				 Cwd            => '0',
				},
	      dist	        => {COMPRESS => 'gzip', SUFFIX => 'tar.gz'},
);
