use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Mail::IMAP2SMS',
    AUTHOR              => 'Roy Crowder <rcrowder@cpan.org>',
    VERSION_FROM        => 'lib/Mail/IMAP2SMS.pm',
    ABSTRACT_FROM       => 'lib/Mail/IMAP2SMS.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => '',
        'Net::IMAP::Simple' => '',
        'Net::IMAP::Simple::SSL' => '',
        'Email::Simple' => '',
        'Mail::Sendmail' => '',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Mail-IMAP2SMS-*' },
);
