use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Ecma48::Util',
    AUTHOR              => q{Josef <josef@cpan.org>},
    VERSION_FROM        => 'lib/Ecma48/Util.pm',
    ABSTRACT_FROM       => 'lib/Ecma48/Util.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0, Carp => 0, re => 0, Exporter => 0,
    },
    MIN_PERL_VERSION    => '5.014',
    #dist               => { COMPRESS => 'gzip -9f', SUFFIX => '.gz', },
    clean               => { FILES => 'Ecma48-Util-*' },
);
