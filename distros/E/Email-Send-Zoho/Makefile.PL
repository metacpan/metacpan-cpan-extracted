use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Email::Send::Zoho',
    AUTHOR              => q{Ken Peng <yhpeng@cpan.org>},
    VERSION_FROM        => 'lib/Email/Send/Zoho.pm',
    ABSTRACT_FROM       => 'lib/Email/Send/Zoho.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'MIME::Lite' => 0,
        'MIME::Words' => 0,
        'Authen::SASL' => 0,
        'Net::SMTP::SSL' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Email-Send-Zoho-*' },
);
