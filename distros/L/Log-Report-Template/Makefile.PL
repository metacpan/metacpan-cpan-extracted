use ExtUtils::MakeMaker;

use 5.010;

my $version = '0.13';

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

  , META_MERGE =>
      { 'meta-spec' => { version => 2 }
      , resources  =>
         { repository =>
            { type => 'git'
            , url  => 'https://github.com/markov2/perl5-Log-Report-Template.git'
            , web  => 'https://github.com/markov2/perl5-Log-Report-Template'
            }
         }
      , homepage => 'http://perl.overmeer.net/CPAN/'
      , license  => [ 'http://dev.perl.org/licenses/' ]
      }

  );

sub MY::postamble { <<'__POSTAMBLE' }

# for OODoc's oodist, DIST
RAWDIR          = ../public_html/log-report-template/raw
DISTDIR         = ../public_html/log-report-template/source
SKIP_LINKS      = Dancer2::Config

# for OODoc's oodist, POD
FIRST_YEAR      = 2017
EMAIL           = markov@cpan.org
WEBSITE         = http://perl.overmeer.net/CPAN/
EXTENDS         = ../../perl/LogOpt:../String-Print:../../perl/LogLex:../../perl/LogReport

__POSTAMBLE

# for translation tables
#linkext::
#	- PERL5LIB="lib:$PERL5LIB" bin/xgettext-perl --mode=VERBOSE \
#	    -p lib/Log/Report/messages lib bin
