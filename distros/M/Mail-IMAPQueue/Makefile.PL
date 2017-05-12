use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Mail::IMAPQueue',
    AUTHOR              => q{Mahiro Ando <mahiro@cpan.org>},
    VERSION_FROM        => 'lib/Mail/IMAPQueue.pm',
    ABSTRACT_FROM       => 'lib/Mail/IMAPQueue.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'gpl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'    => '0.96',
        'Mail::IMAPClient' => '3.26',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Mail-IMAPQueue-*' },
);
