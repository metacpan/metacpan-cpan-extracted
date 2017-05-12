BEGIN{ require 5.008 };
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Font::GlyphNames',
    AUTHOR              => 'Father Chrysostomos',
    VERSION_FROM        => 'lib/Font/GlyphNames.pm',
    ABSTRACT_FROM       => 'lib/Font/GlyphNames.pm',
    PL_FILES            => {},
    PREREQ_PM => {
	 Encode                 => 0,
	 Exporter               => 0,
	'File::Spec::Functions' => 0,
	 strict                 => 0,
	 subs                   => 0,
	 warnings               => 0,
# for testing only:
	 lib         => 0,
	'Test::More' => 0,
	 utf8        => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz',
                             TAR => 'COPYFILE_DISABLE=1 tar' },
    clean               => { FILES => 'Font-GlyphNames-*' },
);
