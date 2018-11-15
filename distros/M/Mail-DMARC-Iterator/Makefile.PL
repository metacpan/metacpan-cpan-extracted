use strict;
use ExtUtils::MakeMaker 6.46;
require v5.10.0;
WriteMakefile(
    NAME => 'Mail::DMARC::Iterator',
    ABSTRACT => 'validate mails against DMARC policy the asynchronous way',
    AUTHOR => 'Steffen Ullrich <sullr@cpan.org>',
    LICENSE => 'perl',
    META_MERGE => {
        resources => {
            license     => 'http://dev.perl.org/licenses/',
            repository  => 'https://github.com/noxxi/p5-mail-dmarc-iterator',
            homepage  => 'https://github.com/noxxi/p5-mail-dmarc-iterator',
            bugtracker  => 'https://rt.cpan.org/Dist/Display.html?Queue=Mail-DMARC-Iterator',
        },
    },
    PREREQ_PM => {
        'Mail::SPF::Iterator' => 1.115,
        'Mail::DKIM::Iterator' => 1.002,
    },
    VERSION_FROM => 'lib/Mail/DMARC/Iterator.pm',
);

