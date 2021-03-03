use strict;
use ExtUtils::MakeMaker 6.46;
require v5.10.0;
WriteMakefile(
    NAME => 'Mail::DKIM::Iterator',
    ABSTRACT => 'validate DKIM signatures and sign the asynchronous way',
    AUTHOR => 'Steffen Ullrich <sullr@cpan.org>',
    LICENSE => 'perl',
    META_MERGE => {
        resources => {
            license     => 'http://dev.perl.org/licenses/',
            repository  => 'https://github.com/noxxi/p5-mail-dkim-iterator',
            homepage  => 'https://github.com/noxxi/p5-mail-dkim-iterator',
            bugtracker  => 'https://github.com/noxxi/p5-mail-dkim-iterator/issues',
        },
    },
    PREREQ_PM => {
	'Crypt::OpenSSL::RSA' => 0,
    },
    VERSION_FROM => 'lib/Mail/DKIM/Iterator.pm',
);
