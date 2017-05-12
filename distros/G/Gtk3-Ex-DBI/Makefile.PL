use 5.008000;
use ExtUtils::MakeMaker;

WriteMakefile(
		NAME		=> 'Gtk3::Ex::DBI',
		VERSION_FROM	=> 'lib/Gtk3/Ex/DBI.pm',
		PREREQ_PM	=> {
					'Gtk3'				=> 0.01,
					'DBI'				=> 1.30
				   },
		($] >= 5.005 ?     ## Add these new keywords supported since 5.005
					(AUTHOR		=> 'Daniel Kasak <d.j.kasak.dk@gmail.com>') : ()),
);
