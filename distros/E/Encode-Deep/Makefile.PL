use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Encode::Deep',
    AUTHOR              => q{Sebastian willing <sewi@cpan.org>},
    VERSION_FROM        => 'lib/Encode/Deep.pm',
    ABSTRACT_FROM       => 'lib/Encode/Deep.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Carp' => 0,
        'Exporter' => 0,
        'Encode' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Encode-Deep-*' },
);
