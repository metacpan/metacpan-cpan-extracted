use ExtUtils::MakeMaker;

require 5.010;

use IO::Handle;

my $VERSION = '3.000';

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
 , LICENSE    => 'perl'
 );

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
RAWDIR          = ../public_html/mail-transport/raw
DISTDIR         = ../public_html/mail-transport/source

LICENSE         = artistic
EXTENDS			= ../MailMessage:../MailPOP:../MailIMAP

# for POD
FIRST_YEAR      = 2001
EMAIL           = perl@overmeer.net
WEBSITE         = http://perl.overmeer.net/mailbox/
PODTAIL         = ../MailBox-shared-podtail


__POSTAMBLE
