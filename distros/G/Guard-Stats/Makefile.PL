use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Guard::Stats',
    AUTHOR              => q{Konstantin S. Uvarin <khedin@gmail.com>},
    VERSION_FROM        => 'lib/Guard/Stats.pm',
    ABSTRACT_FROM       => 'lib/Guard/Stats.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Test::Exception' => 0,
	'Data::Dumper' => 0,
	'Time::HiRes' => 0,
	'Carp' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Guard-Stats-*' },
);
