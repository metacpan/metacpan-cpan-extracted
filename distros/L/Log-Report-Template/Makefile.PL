use ExtUtils::MakeMaker;

use 5.010;

my $version = '0.12';

my %prereq  =
  ( Test::More               => 0.86
  , Scalar::Util             => 0
  , Log::Report              => 1.20
  , Log::Report::Lexicon     => 1.08
  , Template                 => 2.26
  , String::Print            => 0.91
  , File::Find               => 0
  );

WriteMakefile
  ( NAME      => 'Log::Report::Template'
  , VERSION   => $version
  , PREREQ_PM => \%prereq

  , AUTHOR    => 'Mark Overmeer'
  , ABSTRACT  => 'template toolkit with translations'
  , LICENSE   => 'perl'
  );

sub MY::postamble { <<'__POSTAMBLE' }

# for OODoc's oodist, DIST
RAWDIR          = ../public_html/log-report-template/raw
DISTDIR         = ../public_html/log-report-template/source
SKIP_LINKS      = Dancer2::Config

# for OODoc's oodist, POD
FIRST_YEAR      = 2017
EMAIL           = perl@overmeer.net
WEBSITE         = http://perl.overmeer.net/log-report/
EXTENDS         = ../LogOpt:../Print:../LogLex:../LogReport

__POSTAMBLE

# for translation tables
#linkext::
#	- PERL5LIB="lib:$PERL5LIB" bin/xgettext-perl --mode=VERBOSE \
#	    -p lib/Log/Report/messages lib bin
