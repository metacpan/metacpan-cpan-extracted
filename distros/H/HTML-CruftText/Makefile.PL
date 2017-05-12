use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'HTML::CruftText',
    AUTHOR              => q{David Larochelle <dlarochelle@cyber.law.harvard.edu>},
    VERSION_FROM        => 'lib/HTML/CruftText.pm',
    ABSTRACT_FROM       => 'lib/HTML/CruftText.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'agpl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'           => 0,
        'Test::Pod'            => 1.45,
        'Test::Pod::Coverage'  => 1.08,

        'Time::HiRes'      => 1.51,
        'List::MoreUtils'  => 0.33,
        'Readonly'         => 1.03,
        'Test::NoWarnings' => 1.04,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'HTML-CruftText-*' },
);
