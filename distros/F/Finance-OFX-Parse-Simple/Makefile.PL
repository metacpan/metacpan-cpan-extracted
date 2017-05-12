use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Finance::OFX::Parse::Simple',
    AUTHOR              => 'Jeremy Jones <jjones@cpan.org>',
    VERSION_FROM        => 'lib/Finance/OFX/Parse/Simple.pm',
    ABSTRACT_FROM       => 'lib/Finance/OFX/Parse/Simple.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Finance-OFX-Parse-Simple-*' },
);
