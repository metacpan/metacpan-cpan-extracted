use ExtUtils::MakeMaker;

require 5.010;

use IO::Handle;

my $VERSION = '3.007';

my %prereq =
  ( Carp             => 0
  , Digest::MD5      => 0
  , File::Basename   => 0
  , File::Spec       => 0
  , IO::Socket       => 0
  , IO::Socket::IP   => 0
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
 , LICENSE    => 'perl_5'

 , META_MERGE =>
      { 'meta-spec' => { version => 2 }
      , resources  =>
          { repository =>
              { type => 'git'
              , url  => 'https://github.com/markov2/perl5-Mail-Box-POP3.git'
              , web  => 'https://github.com/markov2/perl5-Mail-Box-POP3'
              }
          , homepage => 'http://perl.overmeer.net/CPAN/'
          , license  => [ 'http://dev.perl.org/licenses/' ]
          }
      }

 );

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
RAWDIR          = ../public_html/mail-box-pop3/raw
DISTDIR         = ../public_html/mail-box-pop3/source
EXTENDS         = ../Mail-Message:../Mail-Transport:../Mail-Box

# for POD
FIRST_YEAR      = 2001
EMAIL           = markov@cpan.org
WEBSITE         = http://perl.overmeer.net/CPAN/

__POSTAMBLE
