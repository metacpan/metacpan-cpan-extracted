use ExtUtils::MakeMaker;

use 5.008;

my $version = '1.05';

my %prereq  =
  ( Test::More    => '0.86'
  , String::Print => '0.91'

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

  , META_MERGE =>
      { 'meta-spec' => { version => 2 }
      , resources  =>
         { repository =>
            { type => 'git'
            , url  => 'https://github.com/markov2/perl5-Log-Report-Optional.git'
            , web  => 'https://github.com/markov2/perl5-Log-Report-Optional'
            }
         }
      , homepage => 'http://perl.overmeer.net/CPAN/'
      , license  => [ 'http://dev.perl.org/licenses/' ]
      }
  );

sub MY::postamble { <<'__POSTAMBLE' }

# for OODoc's oodist, DIST
RAWDIR          = ../public_html/log-report-optional/raw
DISTDIR         = ../public_html/log-report-optional/source

# for OODoc's oodist, POD
FIRST_YEAR      = 2013
EMAIL           = markov@cpan.org
WEBSITE         = http://perl.overmeer.net/CPAN/
EXTENDS         = ../String-Print

__POSTAMBLE
