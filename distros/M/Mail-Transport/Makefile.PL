use ExtUtils::MakeMaker;

require 5.010;

use IO::Handle;

my $VERSION = '3.004';

my %prereq =
 ( Carp           => 0
 , List::Util     => 0
 , IO::Socket     => 0
 , File::Spec     => 0.7
 , Errno          => 0
 , Net::SMTP      => 0

 , Mail::Reporter => 3
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
 ( NAME       => 'Mail::Transport'
 , VERSION    => $VERSION
 , AUTHOR     => 'Mark Overmeer'
 , ABSTRACT   => 'Email message exchange'
 , PREREQ_PM  => \%prereq
 , LICENSE    => 'perl_5'

 , META_MERGE =>
      { 'meta-spec' => { version => 2 }
      , resources  =>
          { repository =>
              { type => 'git'
              , url  => 'https://github.com/markov2/perl5-Mail-Transport.git'
              , web  => 'https://github.com/markov2/perl5-Mail-Transport'
              }
          , homepage => 'http://perl.overmeer.net/CPAN/'
          , license  => [ 'http://dev.perl.org/licenses/' ]
          }
      }
 );

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
RAWDIR          = ../public_html/mail-transport/raw
DISTDIR         = ../public_html/mail-transport/source

LICENSE         = perl
EXTENDS			= ../Mail-Message:../Mail-Box-POP3:../Mail-Box-IMAP4

# for POD
FIRST_YEAR      = 2001
EMAIL           = markov@cpan.org
WEBSITE         = http://perl.overmeer.net/CPAN/

__POSTAMBLE
