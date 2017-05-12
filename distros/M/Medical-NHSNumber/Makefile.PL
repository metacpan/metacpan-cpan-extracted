use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Medical::NHSNumber',
    AUTHOR              => q{Dr Spiros Denaxas <s.denaxas@gmail.com>},
    VERSION_FROM        => 'lib/Medical/NHSNumber.pm',
    ABSTRACT_FROM       => 'lib/Medical/NHSNumber.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Medical-NHSNumber-*' },
);
