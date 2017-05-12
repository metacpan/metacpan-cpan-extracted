use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Digest::FNV::PurePerl',
    AUTHOR              => q{Jeffrey Webster <jeff.webster@zogmedia.com>},
    VERSION_FROM        => 'lib/Digest/FNV/PurePerl.pm',
    ABSTRACT_FROM       => 'lib/Digest/FNV/PurePerl.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Digest-FNV-PurePerl-*' },
);
