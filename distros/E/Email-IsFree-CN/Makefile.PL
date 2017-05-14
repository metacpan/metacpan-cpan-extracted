use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Email::IsFree::CN',
    AUTHOR              => q{Xiaolan Fu <GZ_AF@yahoo.com>},
    VERSION_FROM        => 'lib/Email/IsFree/CN.pm',
    ABSTRACT_FROM       => 'lib/Email/IsFree/CN.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Email-IsFree-CN-*' },
);
