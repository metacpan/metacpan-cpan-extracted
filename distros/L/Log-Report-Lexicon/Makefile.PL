use ExtUtils::MakeMaker;

use 5.010;

my $version = '1.10';

my %prereq  =
  ( Test::More               => '0.86'
  , Data::Dumper             => 0
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

  , META_MERGE =>
      { 'meta-spec' => { version => 2 }
      , resources  =>
         { repository =>
            { type => 'git'
            , url  => 'https://github.com/markov2/perl5-Log-Report-Lexicon.git'
            , web  => 'https://github.com/markov2/perl5-Log-Report-Lexicon'
            }
         }
      , homepage => 'http://perl.overmeer.net/CPAN/'
      , license  => [ 'http://dev.perl.org/licenses/' ]
      }

  );

sub MY::postamble { <<'__POSTAMBLE' }

# for OODoc's oodist, DIST
RAWDIR          = ../public_html/log-report-lexicon/raw
DISTDIR         = ../public_html/log-report-lexicon/source

# for OODoc's oodist, POD
FIRST_YEAR      = 2007
EMAIL           = markov@cpan.org
WEBSITE         = http://perl.overmeer.net/CPAN/
EXTENDS         = ../Log-Report-Optional:../String-Print:../../perl/LogReport:../Log-Report-Template

__POSTAMBLE

# for translation tables
#linkext::
#	- PERL5LIB="lib:$PERL5LIB" bin/xgettext-perl --mode=VERBOSE \
#	    -p lib/Log/Report/messages lib bin
