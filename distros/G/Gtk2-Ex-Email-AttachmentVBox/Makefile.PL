use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
			  NAME                => 'Gtk2::Ex::Email::AttachmentVBox',
			  AUTHOR              => 'Zane C. Bowers-Hadley <vvelox@vvelox.net>',
			  VERSION_FROM        => 'lib/Gtk2/Ex/Email/AttachmentVBox.pm',
			  ABSTRACT_FROM       => 'lib/Gtk2/Ex/Email/AttachmentVBox.pm',
			  ($ExtUtils::MakeMaker::VERSION >= 6.3002
			   ? ('LICENSE'=> 'perl')
			   : ()),
			  PL_FILES            => {},
			  PREREQ_PM => {
							'Test::More' => 0,
							'Gtk2'=>0,
							'File::MimeInfo'=>0,
							'Gtk2::SimpleList'=>0,
							},
			  dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
			  clean               => { FILES => 'Gtk2-Ex-Email-AttachmentVBox-*' },
			  );
