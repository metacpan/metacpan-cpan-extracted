use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Finance::Bank::IE::PermanentTSB',
    VERSION_FROM      => 'lib/Finance/Bank/IE/PermanentTSB.pm', # finds $VERSION
    PREREQ_PM         => {
        'WWW::Mechanize' => 1.34,
        'HTML::TokeParser' => 2.37,
        'Date::Calc' => 5.4,
        'Test::More' => 0.62,
        'Test::MockObject' => 1.07,
    }, 
    ABSTRACT_FROM  => 'lib/Finance/Bank/IE/PermanentTSB.pm',
    AUTHOR         => 'Angelo "pallotron" Failla <pallotron@freaknet.org>',
    EXE_FILES      => [qw(ptsb)],
    dist           => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean          => { FILES => qw(t/tmpl) },
);
