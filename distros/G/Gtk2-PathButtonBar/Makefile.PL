use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
			  NAME                => 'Gtk2::PathButtonBar',
			  AUTHOR              => 'Zane C. Bowers <vvelox@vvelox.net>',
			  VERSION_FROM        => 'lib/Gtk2/PathButtonBar.pm',
			  ABSTRACT_FROM       => 'lib/Gtk2/PathButtonBar.pm',
			  PL_FILES            => {},
			  PREREQ_PM => {
							'Test::More' => 0,
							'Gtk2' => 0,
							},
			  dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
			  clean               => { FILES => 'Gtk2-PathButtonBar-*' },
			  );
