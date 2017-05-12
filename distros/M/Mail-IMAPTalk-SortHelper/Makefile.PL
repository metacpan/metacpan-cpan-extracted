use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Mail::IMAPTalk::SortHelper',
    AUTHOR              => 'Zane C. Bowers-Hadley <vvelox@vvelox.net>',
    VERSION_FROM        => 'lib/Mail/IMAPTalk/SortHelper.pm',
    ABSTRACT_FROM       => 'lib/Mail/IMAPTalk/SortHelper.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
				  'Test::More' => 0,
				  'Mail::IMAPTalk' => 0,
				  'Mail::Cache' => 0,
				  'Mail::IMAPTalk::MailCache' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Mail-IMAPTalk-SortHelper-*' },
);
