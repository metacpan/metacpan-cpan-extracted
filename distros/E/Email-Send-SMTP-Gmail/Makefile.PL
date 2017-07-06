use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Email::Send::SMTP::Gmail',
    AUTHOR              => q{Juan José 'Peco' San Martín <peco@cpan.org>},
    VERSION_FROM        => 'lib/Email/Send/SMTP/Gmail.pm',
    ABSTRACT_FROM       => 'lib/Email/Send/SMTP/Gmail.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Net::SMTP' => 3.10,
        'Net::SMTP_auth' => 0,
        'MIME::Base64' => 0,
        'File::Spec' => 0,
        'LWP::MediaTypes' => 0,
        'Email::Date::Format' => 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Email-Send-SMTP-Gmail-*' },
    test                => {TESTS => 't/*.t'}
);
