use ExtUtils::MakeMaker;

require 5.010;

use IO::Handle;

my $VERSION = '3.008';

my %prereq =
 ( Carp           => 0
 , Cwd            => 0
 , Date::Parse    => 0
 , Devel::GlobalDestruction => 0.09
 , Errno          => 0
 , Fcntl          => 0
 , File::Basename => 0
 , File::Spec     => 0.7
 , File::Compare  => 0
 , File::Copy     => 0
 , File::Remove   => 0.20
 , File::Temp     => 0
 , IO::Scalar     => 0
 , Mail::Message  => 3.008
 , Mail::Transport => 3.003
 , Object::Realize::Later => 0.19
 , POSIX          => 0
 , Scalar::Util   => 1.13
 , Sys::Hostname  => 0.0
 , Test::More     => 0.47

# Currently, it seems to be wise not to depend on these
#   Mail::SpamAssassin    split-off?
#   File::FcntLock
 );


my @errors;
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
 ( NAME       => 'Mail::Box'
 , VERSION    => $VERSION
 , AUTHOR     => 'Mark Overmeer'
 , ABSTRACT   => 'complete E-mail handling suite'
 , PREREQ_PM  => \%prereq
 , LICENSE    => 'perl_5'

 , META_MERGE =>
      { 'meta-spec' => { version => 2 }
      , resources  =>
          { repository =>
              { type => 'git'
              , url  => 'https://github.com/markov2/perl5-Mail-Box.git'
              , web  => 'https://github.com/markov2/perl5-Mail-Box'
              }
          , homepage => 'http://perl.overmeer.net/CPAN/'
          , license  => [ 'http://dev.perl.org/licenses/' ]
          }
      }
 );

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
RAWDIR          = ../public_html/mail-box/raw
DISTDIR         = ../public_html/mail-box/source
EXTENDS         = ../User-Identity:../MIME-Types:../Object-Realize-Later:../MailTools:../Mail-Box-Parser-C:../Mail-Message:../Mail-Transport:../Mail-Box-IMAP4:../Mail-Box-POP3:../../perl/MailDbx:../HTML-FromMail

# for POD
FIRST_YEAR      = 2001
EMAIL           = markov@cpan.org
WEBSITE         = http://perl.overmeer.net/CPAN/

# for HTML
HTML_OUTPUT     = ../public_html/mailbox/html
HTML_DOCROOT    = /mailbox/html
HTML_PACKAGE    = ../public_html/mailbox/htmlpkg

__POSTAMBLE
