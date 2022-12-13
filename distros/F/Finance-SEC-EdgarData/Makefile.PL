use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Finance::SEC::EdgarData',
    AUTHOR              => q{Andrew Shapiro <trski@cpan.org>},
    VERSION_FROM        => 'lib/Finance/SEC/EdgarData.pm',
    ABSTRACT_FROM       => 'lib/Finance/SEC/EdgarData.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'XML::Bare' => 0.53,
        'JSON::XS' => 4.02,
        'LWP::UserAgent' => 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Finance-SEC-EdgarData-*' },
);
