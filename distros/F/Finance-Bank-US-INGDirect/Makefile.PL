use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Finance::Bank::US::INGDirect',
    AUTHOR              => q{Steven N. Severinghaus <sns-perl@severinghaus.org>},
    VERSION_FROM        => 'lib/Finance/Bank/US/INGDirect.pm',
    ABSTRACT_FROM       => 'lib/Finance/Bank/US/INGDirect.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    META_MERGE => {
        resources => {
            repository => 'https://github.com/horsepunchkid/Finance-Bank-US-INGDirect',
        },
    },
    PREREQ_PM => {
        'Test::More' => 0,
        'Date::Parse' => 0,
        'LWP::UserAgent' => 0,
        'HTTP::Cookies' => 0,
        'HTML::TableExtract' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Finance-Bank-US-INGDirect-*' },
);
