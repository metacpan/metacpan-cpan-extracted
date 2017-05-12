use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
			  NAME                => 'Gtk2::ImageView::Browser',
			  AUTHOR              => 'Zane C. Bowers <vvelox@vvelox.net>',
			  VERSION_FROM        => 'lib/Gtk2/ImageView/Browser.pm',
			  ABSTRACT_FROM       => 'lib/Gtk2/ImageView/Browser.pm',
			  ($ExtUtils::MakeMaker::VERSION >= 6.3002
			   ? ('LICENSE'=> 'perl')
			   : ()),
			  PL_FILES            => {},
			  INST_SCRIPT => 'bin',
			  PREREQ_PM => {
							'Test::More'=>0,
							'Gtk2'=>0,
							'Gtk2::ImageView'=>0,
							'Gtk2::Ex::Simple::List'=>0,
							'File::MimeInfo::Magic'=>0,
							'Gtk2::Gdk::Keysyms'=>0,
							'Cwd'=>0,
							'Image::Size'=>0,
							},
			  dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
			  clean               => { FILES => 'Gtk2-ImageView-Browser-*' },
			  );
