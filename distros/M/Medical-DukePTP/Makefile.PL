use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Medical::DukePTP',
    AUTHOR              => q{Spiros Denaxas <s.denaxas@gmail.com>},
    VERSION_FROM        => 'lib/Medical/DukePTP.pm',
    ABSTRACT_FROM       => 'lib/Medical/DukePTP.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Medical-DukePTP-*' },
);
