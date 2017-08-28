use ExtUtils::MakeMaker;

use 5.010;

my $version = '1.09';

my %prereq  =
  ( Test::More               => '0.86'
  , Fcntl                    => 0
  , File::Basename           => 0
  , File::Find               => 0
  , File::Spec               => 0
  , File::Temp               => 0
  , IO::File                 => 0
  , List::Util               => 0
  , Scalar::Util             => 0
  , Log::Report              => 1.22
  , Pod::Usage               => 0
  , POSIX                    => 0
  , Encode                   => 0

  # sometimes needed, dependencies too large
  # PPI
  # Locale::gettext
  );

$prereq{ 'Win32::TieRegistry' } = 0.24
    if $^O eq 'MSWin32';

WriteMakefile
  ( NAME      => 'Log::Report::Lexicon'
  , VERSION   => $version
  , PREREQ_PM => \%prereq
  , EXE_FILES => [ 'bin/xgettext-perl' ]

  , AUTHOR    => 'Mark Overmeer'
  , ABSTRACT  => 'Log::Report translation table management'
  , LICENSE   => 'perl'
  );

sub MY::postamble { <<'__POSTAMBLE' }

# for OODoc's oodist, DIST
RAWDIR          = ../public_html/log-report-lexicon/raw
DISTDIR         = ../public_html/log-report-lexicon/source

# for OODoc's oodist, POD
FIRST_YEAR      = 2007
EMAIL           = perl@overmeer.net
WEBSITE         = http://perl.overmeer.net/log-report/
EXTENDS         = ../LogOpt:../Print:../LogReport:../LogTT

__POSTAMBLE

# for translation tables
#linkext::
#	- PERL5LIB="lib:$PERL5LIB" bin/xgettext-perl --mode=VERBOSE \
#	    -p lib/Log/Report/messages lib bin
