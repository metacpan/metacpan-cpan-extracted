use ExtUtils::MakeMaker;

use 5.010;

WriteMakefile
  ( NAME	 	 => 'Geo::ISO19139'
  , VERSION	     => '0.11'
  , PREREQ_PM    =>
   { XML::Compile         => 0.84
   , XML::Compile::Tester => 0.02
   , XML::Compile::Cache  => 0.10
   , Log::Report          => 0.19
   , Geo::GML             => 0.18

   , Test::More           => 0.54
   }

  , EXE_FILES    => []
  , AUTHOR       => 'Mark Overmeer'
  , ABSTRACT     => 'Geography metadata standard'
  , LICENSE      => 'perl'
  , META_MERGE =>
      { 'meta-spec' => { version => 2 }
      , resources  =>
          { repository =>
              { type => 'git'
              , url  => 'https://github.com/markov2/perl5-Geo-ISO19139.git'
              , web  => 'https://github.com/markov2/perl5-Geo-ISO19139'
              }
          }
          , homepage => 'http://perl.overmeer.net/CPAN/'
          , license  => [ 'http://dev.perl.org/licenses/' ]
      }
  );

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
RAWDIR          = ../public_html/geo-iso19139/raw
DISTDIR         = ../public_html/geo-iso19139/source
LICENSE         = perl

# for POD
FIRST_YEAR      = 2008,2018
EMAIL           = markov@cpan.org
WEBSITE         = http://perl.overmeer.net/CPAN/
__POSTAMBLE
