use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Finance::Bank::Halifax::Sharedealing',
    AUTHOR              => q{Rayner Lucas <cpan@magic-cookie.co.uk>},
    VERSION_FROM        => 'lib/Finance/Bank/Halifax/Sharedealing.pm',
    ABSTRACT_FROM       => 'lib/Finance/Bank/Halifax/Sharedealing.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'HTML::TokeParser' => 0,
        'WWW::Mechanize' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Finance-Bank-Halifax-Sharedealing-*' },
);
