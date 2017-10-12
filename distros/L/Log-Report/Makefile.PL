use ExtUtils::MakeMaker;

use 5.010;

my $version = '1.22';

my %prereq  =
  ( Test::More               => '0.86'
  , Sys::Syslog              => '0.27'
  , Encode                   => '2.00'
  , Scalar::Util             => 0
  , Devel::GlobalDestruction => '0.09'
  , Log::Report::Optional    => '1.03'
  , String::Print            => '0.91'
  );

# Upgrade L::R::Lexicon if installed
eval "require Log::Report::Extract";
#warn $@;
unless($@)
{   my $v = $Log::Report::Extract::VERSION || '1.00';
    if($v < 1.00) { warn <<'__CHANGES_100'; sleep 10 }
***************************************************************
WARNING: with Log::Report 1.00, the distribution got spit into
   four separate components.  If you use *translations*, then
   you have to upgrade Log::Report::Lexicon as well.  You may 
   need to add dependencies to that module as well.
***************************************************************
__CHANGES_100
}

#use Data::Dumper;
#warn Dumper \%prereq;

WriteMakefile
  ( NAME      => 'Log::Report'
  , VERSION   => $version
  , PREREQ_PM => \%prereq

  , AUTHOR    => 'Mark Overmeer'
  , ABSTRACT  => 'report a problem, pluggable handlers and language support'
  , LICENSE   => 'perl'
  );

sub MY::postamble { <<'__POSTAMBLE' }

# for OODoc's oodist, DIST
RAWDIR          = ../public_html/log-report/raw
DISTDIR         = ../public_html/log-report/source
SKIP_LINKS      = Dancer2::Config

# for OODoc's oodist, POD
FIRST_YEAR      = 2007
EMAIL           = perl@overmeer.net
WEBSITE         = http://perl.overmeer.net/log-report/
EXTENDS      	= ../LogOpt:../Print:../LogLex:../LogTT

# for OODoc's oodist, HTML
HTML_OUTPUT     = ../public_html/log-report/html
HTML_DOCROOT    = /log-report/html
HTML_PACKAGE    = ../public_html/log-report/htmlpkg

__POSTAMBLE

# for translation tables
#linkext::
#	- PERL5LIB="lib:$PERL5LIB" bin/xgettext-perl --mode=VERBOSE \
#	    -p lib/Log/Report/messages lib bin
