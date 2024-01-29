use ExtUtils::MakeMaker;

require 5.010;

use IO::Handle;

my $VERSION = '3.015';

my @optional =
( 
  [ Mail::Internet => '2.01', distr => 'MailTools', reason  => <<'REASON' ]
Many existing e-mail applications use Mail::Internet objects.  If
you want automatic conversions for compatibility, you need this.
REASON

, [ MIME::Entity => '3.0', distr  => 'MIME::Tools', reason  => <<'REASON' ]
MIME::Entity extends Mail::Internet messages with multipart handling
and composition.  Install this when you want compatibility with
distrs which are based on this kind of messages.
REASON

, [ HTML::TreeBuilder => '3.13', reason => <<'REASON' ]
The tree builder is used by the HTML::Format* packages.
Version 3.12 is wrong, so you should install a newer version
if you want smart html conversions.
REASON

, [ Time::HiRes => '1.51', reason => <<'REASON' ]
When installed, unique message-ids will be created using gettimeofday.
Otherwise, generated message-ids will not be thread/fork safe.
REASON

, [ HTML::FormatText => '2.01', reason => <<'REASON' ]
Plug-in which converts HTML to Postscript or plain text.
REASON

, [ Net::Domain => 0, reason => <<'REASON' ]
Better detection of full hostname.
REASON
);

my %prereq =
 ( Date::Format   => 0
 , Date::Parse    => 0
 , Encode         => 2.26
 , File::Spec     => 0.7
 , IO::Scalar     => 0
 , Mail::Address  => 2.17
 , MIME::Base64   => 0
 , MIME::Types    => 1.004
 , Scalar::Util   => 1.13
 , Sys::Hostname  => 0
 , Test::More     => 0.47
 , Time::Zone     => 0
 , URI            => 1.23
 , User::Identity => 1.02
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

OPTIONAL:
foreach my $optional (sort {$a->[0] cmp $b->[0]} @optional)
{   my ($module, $version, %args) = @$optional;
    my $requirements = $args{requires} || sub {1};
    next unless $requirements->();

    if($module eq 'MIME::Entity')
    {   # work-around for awkward development situation at home,
        # where the VERSION string is not in the development pre-release.
        no warnings;
        eval "require Mail::Internet";
        unless($@)
        {   $Mail::Internet::VERSION ||= '2.00';
            $Mail::Field::VERSION    ||= '2.00';
            $Mail::Header::VERSION   ||= '2.00';
        }
    }

#   print "\n";
    eval "require $module";
    if($@)
    {   if($@ =~ m/^Can't locate /)
        {   print "**** Optional $module is not installed\n";
            next OPTIONAL;
        }

        print "**** Optional $module compilation failed:\n$@\n";
        # try reinstallation
    }
    elsif(eval '$module->VERSION($version)' && $@)
    {   my $error = $@ || '';
        $error =~ s/[\r\n]+$//;
        print "**** Optional $module too old: requires $version but is ",
            $module->VERSION,";$error\n";
    }
    else
    {   my $v = $module->VERSION;
        my $r = $v eq $version ? ''
              : $version eq 0  ? " (any version will do)"
              :                  " (at least $version required)";

        print "**** Found optional $module version $v$r\n";
        next OPTIONAL;
    }

    my $reason = $args{reason};
    $reason =~ s/^/     /gm;
    $reason =~ s/\A    /Use:/;
    print $reason;

    if(my $warn = $args{warning})
    {   $warn =~ s/^/     /gm;
        $warn =~ s/\A    /WARN/;
        print $warn;
    }
    my $distr = $args{distr} || $module;

    $prereq{$distr} = $version;
    print "     Added $distr version $version to the requirements\n";
}

WriteMakefile
 ( NAME       => 'Mail::Message'
 , VERSION    => $VERSION
 , AUTHOR     => 'Mark Overmeer <markov@cpan.org>'
 , ABSTRACT   => 'Processing MIME messages'
 , PREREQ_PM  => \%prereq
 , LICENSE    => 'perl_5'

 , META_MERGE =>
      { 'meta-spec' => { version => 2 }
      , resources  =>
          { repository =>
              { type => 'git'
              , url  => 'https://github.com/markov2/perl5-Mail-Message.git'
              , web  => 'https://github.com/markov2/perl5-Mail-Message'
              }
          , homepage => 'http://perl.overmeer.net/CPAN/'
          , license  => [ 'http://dev.perl.org/licenses/' ]
          }
      }
 );

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
RAWDIR          = ../public_html/mail-message/raw
DISTDIR         = ../public_html/mail-message/source

LICENSE         = perl
EXTENDS			= ../User-Identity:../MIME-Types:../Object-Realize-Later:../MailTools:../Mail-Box-Parser-C:../Mail-Box:../Mail-Transport

# for POD
FIRST_YEAR      = 2001
EMAIL           = markov@cpan.org
WEBSITE         = http://perl.overmeer.net/CPAN/

__POSTAMBLE
