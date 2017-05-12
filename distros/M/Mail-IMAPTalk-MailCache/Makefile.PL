use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Mail::IMAPTalk::MailCache',
    AUTHOR              => 'Zane C. Bowers <vvelox@vvelox.net>',
    VERSION_FROM        => 'lib/Mail/IMAPTalk/MailCache.pm',
    ABSTRACT_FROM       => 'lib/Mail/IMAPTalk/MailCache.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
				  'Test::More' => 0,
				  'Mail::IMAPTalk'=>0,
				  'Mail::Cache'=>'0.1.0',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Mail-IMAPTalk-MailCache-*' },
);
