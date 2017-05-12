use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Finance::NASDAQ::Quote',
    AUTHOR              => 'Ian Kilgore <iank@cpan.org>',
    VERSION_FROM        => 'lib/Finance/NASDAQ/Quote.pm',
    ABSTRACT_FROM       => 'lib/Finance/NASDAQ/Quote.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'LWP::Simple' => 0,
        'HTML::TreeBuilder' => 0,
        'Test::More' => 0,
        'URI' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Finance-NASDAQ-Quote-*' },
);
