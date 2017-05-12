BEGIN { require 5.006 } # our

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'KSx::Analysis::StripAccents',
    AUTHOR              => 'Father Chrysostomos <sprout [hat] cpan . org>',
    VERSION_FROM        => 'lib/KSx/Analysis/StripAccents.pm',
    ABSTRACT_FROM       => 'lib/KSx/Analysis/StripAccents.pm',
    PL_FILES            => {},
    PREREQ_PM => {
         base                             => 0,
         Encode                           => 0,
         KinoSearch::Analysis::Analyzer   => 0,
#         KinoSearch::Analysis::TokenBatch => 0,
         strict                           => 0,
         Text::Unaccent                   => 0,
         warnings                         => 0,
# for testing:
	KinoSearch => .2,
	Test::More => 0,
	utf8       => 0,
    },
    dist               => { COMPRESS => 'gzip -9f', SUFFIX => 'gz',
                            TAR => 'COPYFILE_DISABLE=1 tar' },
    clean              => { FILES => 'KSx-Analysis-StripAccents-*' },
);
