use ExtUtils::MakeMaker;

require 5.010;

use IO::Handle;

my $VERSION = '3.002';

my %prereq =
  ( Carp             => 0
  , Digest::MD5      => 0
  , File::Basename   => 0
  , File::Spec       => 0
  , IO::Socket       => 0
  , List::Util       => 0
  , Socket           => 0
  , Test::More       => 0

  , Mail::Box::FastScalar         => 3
  , Mail::Box::Net                => 3
  , Mail::Box::Test               => 3
  , Mail::Box::Parser::Perl       => 3
  , Mail::Transport::Receive      => 3
  , Mail::Reporter                => 3
  );

foreach my $module (sort keys %prereq)
{   my $reqversion = $prereq{$module};
    eval "require $module";

    if($@ && $@ =~ m/^Can't locate /)
    {   print "    $module is not yet installed\n" }
    elsif($@)
    {   print "    $module produced an error:\n$@";
        push @errors, $module;
    }
    elsif($module->VERSION < $reqversion)
    {   print "    $module version ",$module->VERSION
            , " is outdated; requires $reqversion\n";
    }
    else
    {   print "    $module version ",$module->VERSION
            , " is ok (required is $reqversion)\n";
    }
}

if($errors)
{   die <<'FIX';
*** ERROR! You have to install @errors manually,
*** before you can retry to install MailBox.
FIX
    exit 1;
}

WriteMakefile
 ( NAME       => 'Mail::Box::POP3'
 , VERSION    => $VERSION
 , AUTHOR     => 'Mark Overmeer'
 , ABSTRACT   => 'Mail::Box connector via POP3'
 , PREREQ_PM  => \%prereq
 , LICENSE    => 'perl'
 );

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
RAWDIR          = ../public_html/mail-box-imap4/raw
DISTDIR         = ../public_html/mail-box-imap4/source

EXTENDS			= ../MailMessage:../MailTransport:../MailBox4

# for POD
FIRST_YEAR      = 2001
EMAIL           = perl@overmeer.net
WEBSITE         = http://perl.overmeer.net/mailbox/
PODTAIL         = ../MailBox-shared-podtail

__POSTAMBLE
