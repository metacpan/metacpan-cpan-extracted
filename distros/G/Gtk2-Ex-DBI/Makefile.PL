use 5.008000;
use ExtUtils::MakeMaker;

WriteMakefile(
		NAME		=> 'Gtk2::Ex::DBI',
		VERSION_FROM	=> 'lib/Gtk2/Ex/DBI.pm',
		PREREQ_PM	=> {
					'Gtk2'				=> 1.040,
					'Gtk2::Ex::Dialogs'		=> 0.08,
					'DBI'				=> 1.30
				   },
		($] >= 5.005 ?     ## Add these new keywords supported since 5.005
					(AUTHOR		=> 'Daniel Kasak <dan@entropy.homelinux.org>') : ()),
);
