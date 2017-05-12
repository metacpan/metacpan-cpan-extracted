use ExtUtils::MakeMaker;

require 5.006_001;

use IO::Handle;

my @optional =
(
  [ Template::Magic => '1.02', reason => <<'REASON' ]
Required if you want to use the Template::Magic formatter, which is
not required to run the examples.
REASON

, [ Image::Magick => '5.0', reason => <<'REASON', warning => <<'WARN' ]
When messages contain images, these images can be shown as small
previews.  This is done with Image::Magick, which is quite hard to
install (IMHO).  So if you want to give it a try answer yes.
REASON
If you do not install Image::Magick, some examples will not work.  But
you can always install it later.
WARN

);

my %prereq =
 ( Mail::Box           => 2.051 # used everywhere
 , HTML::FromText      => 2.03  # for HTML::FromMail::Default::HTMLifiers
 , OODoc::Template     => 0.01  # default template system
 , Test::Pod           => 1.00
 );

my $has_readkey;
BEGIN
{   eval "require Term::ReadKey";
    $has_readkey = not length $@;
}

my $default_install_answer = $ENV{INSTALL_HTMLFROMMAIL_OPTIONALS}
    || (-t STDIN ? 'y' : 'n');

print <<'INTRO';
*
**** Installing HTML::FromMail
*
INTRO

print <<'REQUIRED';

* First, I will check the sanity of all required modules... sometimes
* they do not load, for instance if you have installed a new release
* of Perl without upgrading the libraries.

REQUIRED

my @errors;
while(my ($module, $version) = each %prereq)
{   eval "require $module";
    if($@ && $@ =~ m/^Can't locate /)
    {   print "    $module is not yet installed\n" }
    elsif($@)
    {   print "    $module produced an error:\n$@";
        push @errors, $module;
    }
    elsif($module->VERSION < $version)
    {   print "    $module version ",$module->VERSION
            , " is outdated; requires $version\n";
    }
    else
    {   print "    $module version ",$module->VERSION
            , " is ok (required is $version)\n";
    }
}

if($errors)
{   die <<'FIX';
*** ERROR! You have to install @errors manually,
*** before you can retry to install HTML::FromMail.
FIX
    exit 1;
}

print <<'OPTIONAL';

* Now, let me ask you whether you want some optional modules to be
* installed as well.  You can always install these modules later, by
* hand, without a need to re-install HTML::FromMail.
*
OPTIONAL

foreach my $optional (@optional)
{   my ($module, $version, %args) = @$optional;
    my $requirements = $args{requires} || sub {1};
    next unless $requirements->();

    print "\n";
    eval "require $module";
    if($@)
    {   print "**** Optional $module failed:\n$@\n";
    }
    elsif($module->VERSION < $version )
    {   print "**** Optional $module too old: requires $version but is ",
            $module->VERSION,"\n";
    }
    else
    {   print "**** Found optional $module version ", $module->VERSION,
             " (required is $version)\n";
        next;
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
    
    my $install  = $default_install_answer;
    my $key = prompt "Do you want to install $module? yes/no/all", $install;

    if($key eq 'a')
    {   $default_install_answer = 'a';
        $install = 'y';
    }
    else
    {   $install = $key eq 'y' ? 'y' : 'n';
    }

    next unless $install eq 'y';

    my $distr = $args{distr} || $module;

    $prereq{$distr} = $version;
    print "     Added $distr version $version to the requirements\n";
}

$prereq{'Bundle::Template::Magic'} = '0'
   if exists $prereq{'Template::Magic'};

print <<'DONE';

**** Writing Makefile

DONE

WriteMakefile
 ( NAME	      => 'HTML::FromMail'
 , VERSION    => '0.11'
 , AUTHOR     => 'Mark Overmeer'
 , ABSTRACT   => 'Convert E-mail into HTML'
 , PREREQ_PM  => \%prereq
 );

sub MY::postamble { <<'__POSTAMBLE' }

# for OODoc's oodist, DIST
RAWDIR		= ../public_html/html-from-mail/raw
DISTDIR		= ../public_html/html-from-mail/source
LICENSE		= artistic

# for OODoc's oodist, POD
FIRST_YEAR	= 2003,2004,2007
EMAIL		= perl@overmeer.net
WEBSITE		= http://perl.overmeer.net/html-from-mail/

__POSTAMBLE
