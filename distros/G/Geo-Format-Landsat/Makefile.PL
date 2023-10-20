use ExtUtils::MakeMaker;

require 5.008;

WriteMakefile
  ( NAME        => 'Geo::Format::Landsat'
  , VERSION     => '0.90'
  , PREREQ_PM   =>
     { Test::More     => 0.47
     , Geo::Point     => 0.90
     , Geo::Proj4     => 1.01
     }
  , AUTHOR      => 'Mark Overmeer'
  , ABSTRACT    => 'Decode Landsat meta-data'
  , LICENSE     => 'perl'

  , META_MERGE =>
      { 'meta-spec' => { version => 2 }
      , resources  =>
         { repository =>
             { type => 'git'
             , url  => 'https://github.com/markov2/perl5-Geo-Format-Landsat.git'
             , web  => 'https://github.com/markov2/perl5-Geo-Format-Landsat'
             }
         }
      , homepage => 'http://perl.overmeer.net/CPAN/'
      , license  => [ 'http://dev.perl.org/licenses/' ]
      }
  );

#### the next lines are added for OODoc, which generates the
#### distribution.
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
RAWDIR          = ../public_html/geo-format-landsat/raw
DISTDIR         = ../public_html/geo-format-landsat/source
LICENSE         = perl

# for POD
FIRST_YEAR      = 2009
EMAIL           = markov@cpan.org
WEBSITE         = http://perl.overmeer.net/CPAN/
__POSTAMBLE

