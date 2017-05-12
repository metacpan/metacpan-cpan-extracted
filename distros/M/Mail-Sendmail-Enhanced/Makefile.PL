use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Mail::Sendmail::Enhanced',
    AUTHOR           => q{Waldemar Biernacki <wb@webswing.co.uk>},
    VERSION_FROM     => 'lib/Mail/Sendmail/Enhanced.pm',
    ABSTRACT         => 'This is pure Perl module to send email. Emails have multibytes encoding and file attachments',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 1,
    },
    PREREQ_PM => {
        'utf8'           => 0,
        'Mail::Sendmail' => '0.79_16',
        'MIME::Base64'   => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Mail-Sendmail-Enhanced-*' },
);
