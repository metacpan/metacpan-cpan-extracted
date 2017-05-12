use ExtUtils::MakeMaker;

WriteMakefile
 ( NAME          => 'Mail::Box::Parser::C'
 , VERSION_FROM  => 'lib/Mail/Box/Parser/C.pm'
 , PREREQ_PM     =>
     { Test::More => 0.47
     }
 , ABSTRACT      => 'C parser for Mail::Box'
 , AUTHOR        => 'Mark Overmeer'
 , LICENSE       => 'perl'
);

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
RAWDIR          = ../public_html/mailboxc/raw
DISTDIR         = ../public_html/mailboxc/source
LICENSE         = artistic

# for POD
FIRST_YEAR      = 2002
EMAIL           = perl@overmeer.net
WEBSITE         = http://perl.overmeer.net/mailbox/
PODTAIL         = ../MailBox-shared-podtail

__POSTAMBLE

