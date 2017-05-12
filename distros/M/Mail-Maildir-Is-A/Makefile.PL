use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
			  NAME                => 'Mail::Maildir::Is::A',
			  AUTHOR              => q{Zane C. Bowers <vvelox@vvelox.net>},
			  VERSION_FROM        => 'lib/Mail/Maildir/Is/A.pm',
			  ABSTRACT_FROM       => 'lib/Mail/Maildir/Is/A.pm',
			  ($ExtUtils::MakeMaker::VERSION >= 6.3002
			   ? ('LICENSE'=> 'perl')
			   : ()),
			  PL_FILES            => {},
			  PREREQ_PM => {
							'Test::More' => 0,
							},
			  dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
			  clean               => { FILES => 'Mail-Maildir-Is-A-*' },
			  );
