use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
			  NAME                => 'MP3::Tag::Utils',
			  AUTHOR              => q{Zane C. Bowers <vvelox@vvelox.net>},
			  VERSION_FROM        => 'lib/MP3/Tag/Utils.pm',
			  ABSTRACT_FROM       => 'lib/MP3/Tag/Utils.pm',
			  ($ExtUtils::MakeMaker::VERSION >= 6.3002
			   ? ('LICENSE'=> 'perl')
			   : ()),
			  PL_FILES            => {},
			  INST_SCRIPT => 'bin',
			  PREREQ_PM => {
							'Test::More' => 0,
							'MP3::Tag'=>0,
							'Text::NeatTemplate'=>0,
							},
			  dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
			  clean               => { FILES => 'MP3-Tag-Utils-*' },
			  );
