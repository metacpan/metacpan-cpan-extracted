use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Mail::Postfix::Postdrop',
    AUTHOR              => 'Peter Makholm <makholm@one.com>',
    VERSION_FROM        => 'lib/Mail/Postfix/Postdrop.pm',
    ABSTRACT_FROM       => 'lib/Mail/Postfix/Postdrop.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Exporter'   => 5.57,
        'Test::More' => 0,
        'File::Temp' => 0,
        'Email::Abstract' => 0,
        'Email::Address'  => 0,
    },
    ($ExtUtils::MakeMaker::VERSION >= 6.3002 ?
          ('LICENSE'        => 'perl', ) : ()),
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Mail-Postfix-Postdrop-*' },
);
