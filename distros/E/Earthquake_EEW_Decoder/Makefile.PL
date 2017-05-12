use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Earthquake::EEW::Decoder',
    AUTHOR              => q{Satoshi KUBOTA <skubota@cpan.org>},
    VERSION_FROM        => 'lib/Earthquake/EEW/Decoder.pm',
    ABSTRACT_FROM       => 'lib/Earthquake/EEW/Decoder.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Earthquake-EEW-Decoder-*' },
);
