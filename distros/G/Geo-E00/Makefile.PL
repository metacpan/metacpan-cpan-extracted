use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
	NAME		=> 'Geo::E00',
	VERSION_FROM	=> 'lib/Geo/E00.pm', # finds $VERSION
	ABSTRACT	=> 'Perl module to handle E00 files',
	AUTHOR		=> 'Alessandro Zummo <azummo-e00@towertech.it>'	,

	PREREQ_PM	=>
			{
				strict		=> 0,
				vars		=> 0,
				base		=> 0,
				Carp		=> 0,
				Data::Dumper	=> 0,
			},
);
