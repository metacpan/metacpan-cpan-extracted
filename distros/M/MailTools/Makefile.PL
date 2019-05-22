require 5.008001;

use ExtUtils::MakeMaker;

WriteMakefile
 ( NAME      => 'MailTools'
 , DISTNAME  => 'MailTools'
 , VERSION   => '2.21'
 , AUTHOR    => 'Mark Overmeer <markov@cpan.org>'
 , ABSTRACT  => 'Various ancient e-mail related modules'
 , LICENSE   => 'perl_5'

 , PREREQ_PM =>
   { Net::SMTP   => 1.03
   , Net::Domain => 1.05
   , IO::Handle  => 0.00
   , Test::More  => 0.00
   , Date::Format => 0
   , Date::Parse  => 0

   #XXX next deps missing on purpose, to avoid installing a lot which
   #XXX is rarely used:

   # Authen::SASL
   # Net::SMTP::SSL
   }

 , META_MERGE =>
      { 'meta-spec' => { version => 2 }
      , resources  =>
          { repository =>
              { type => 'git'
              , url  => 'https://github.com/markov2/perl5-MailTools.git'
              , web  => 'https://github.com/markov2/perl5-MailTools'
              }
          , homepage => 'http://perl.overmeer.net/CPAN/'
          , license  => [ 'http://dev.perl.org/licenses/' ]
          }
      }
 );

sub MY::postamble { <<'__POSTAMBLE' };

all:: ppd
dist: ppd

# for OODoc's oodist, DIST
RAWDIR		= ../public_html/mailtools/raw
DISTDIR		= ../public_html/mailtools/source
LICENSE		= perl

# for OODoc's oodist, POD
FIRST_YEAR	= 1995
EMAIL		= markov@cpan.org
WEBSITE		= http://perl.overmeer.net/CPAN/

__POSTAMBLE

