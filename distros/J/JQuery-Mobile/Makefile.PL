use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'JQuery::Mobile',
    AUTHOR              => q{Xufeng (Danny) Liang <danny.glue@gmail.com>},
    VERSION_FROM        => 'lib/JQuery/Mobile.pm',
    ABSTRACT_FROM       => 'lib/JQuery/Mobile.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Clone' => 0,
        'HTML::Entities' => 0,
        'Exporter' => '5.57'
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'JQuery-Mobile-*' },
);
