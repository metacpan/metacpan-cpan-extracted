use ExtUtils::MakeMaker;

require 5.010;

use IO::Handle;

my $VERSION = '3.008';

my %prereq =
  ( Date::Parse      => 0
  , Digest::HMAC_MD5 => 0
  , Digest::MD5      => 0
  , File::Compare    => 0
  , File::Copy       => 0
  , File::Spec       => 0
  , File::Temp       => 0.19
  , IO::Socket::IP   => 0
  , List::Util       => 0
  , Mail::IMAPClient => 3.42
  , Scalar::Util     => 0
  , Test::More       => 0

  , Mail::Box                     => 3.007
  , Mail::Box::Manage::User       => 3
  , Mail::Box::Net                => 3
  , Mail::Box::Search             => 3
  , Mail::Box::Test               => 3
  , Mail::Message                 => 3.013
  , Mail::Message::Body::Lines    => 3
  , Mail::Message::Head::Complete => 3
  , Mail::Message::Head::Delayed  => 3
  , Mail::Server                  => 3
  , Mail::Transport::Receive      => 3.004
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
 ( NAME       => 'Mail::Box::IMAP4'
 , VERSION    => $VERSION
 , AUTHOR     => 'Mark Overmeer'
 , ABSTRACT   => 'Mail::Box connector via IMAP4'
 , PREREQ_PM  => \%prereq
 , LICENSE    => 'perl_5'

 , META_MERGE =>
      { 'meta-spec' => { version => 2 }
      , resources  =>
          { repository =>
              { type => 'git'
              , url  => 'https://github.com/markov2/perl5-Mail-Box-IMAP4.git'
              , web  => 'https://github.com/markov2/perl5-Mail-Box-IMAP4'
              }
          , homepage => 'http://perl.overmeer.net/CPAN/'
          , license  => [ 'http://dev.perl.org/licenses/' ]
          }
      }
 );

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
RAWDIR          = ../public_html/mail-box-imap4/raw
DISTDIR         = ../public_html/mail-box-imap4/source
EXTENDS         = ../Mail-Message:../Mail-Transport:../Mail-Box

# for POD
FIRST_YEAR      = 2001
EMAIL           = perl@overmeer.net
WEBSITE         = http://perl.overmeer.net/CPAN/

__POSTAMBLE
