use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'File::FindSimilars',
    AUTHOR              => 'Tong Sun <suntong@cpan.org>',
    VERSION_FROM        => 'lib/File/FindSimilars.pm',
    ABSTRACT_FROM       => 'lib/File/FindSimilars.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'BSD')
      : ()),
    EXE_FILES		=> [ 'bin/findsimilars' ],
    PL_FILES            => {},
    PREREQ_PM => {
        'Class::Accessor::Fast' => 0,
        'Getopt::Long' => 0,
        'Pod::Usage' => 0,
        'Test::More' => 0,
        'Text::Soundex' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'File-FindSimilars-*' },
);
