use ExtUtils::MakeMaker;

use 5.008;

my $version = '1.02';

my %prereq  =
  ( Test::More    => '0.86'
  , String::Print => '0.13'

  # Optional dependency to Log::Report handled in ::Optional.  It is hard
  # to make that work automatically, where Perl's install tools cannot
  # handle recursive dependencies.
  );


WriteMakefile
  ( NAME      => 'Log::Report::Optional'
  , VERSION   => $version
  , PREREQ_PM => \%prereq

  , AUTHOR    => 'Mark Overmeer'
  , ABSTRACT  => 'Log::Report in the lightest form'
  , LICENSE   => 'perl'
  );

sub MY::postamble { <<'__POSTAMBLE' }

# for OODoc's oodist, DIST
RAWDIR          = ../public_html/log-report-optional/raw
DISTDIR         = ../public_html/log-report-optional/source
LICENSE         = artistic

# for OODoc's oodist, POD
FIRST_YEAR      = 2013
EMAIL           = perl@overmeer.net
WEBSITE         = http://perl.overmeer.net/log-report/
EXTENDS		=

__POSTAMBLE
