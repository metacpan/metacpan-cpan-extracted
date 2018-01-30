use ExtUtils::MakeMaker;

require 5.006;

WriteMakefile
  ( NAME      => 'Geo::WKT'
  , VERSION   => '0.96'
  , AUTHOR    => 'Mark Overmeer'
  , ABSTRACT  => 'Geometry in Well-Known Text format'

  , PREREQ_PM =>
     { Geo::Point    => 0.91
     , Test::More    => 0.47
     }

  , META_MERGE =>
      { 'meta-spec' => { version => 2 }
      , resources  =>
         { repository =>
             { type => 'git'
             , url  => 'https://github.com/markov2/perl5-Geo-WKT.git'
             , web  => 'https://github.com/markov2/perl5-Geo-WKT'
             }
         }
      , homepage => 'http://perl.overmeer.net/CPAN/'
      , license  => [ 'http://dev.perl.org/licenses/' ]
      }
  );

sub MY::postamble { <<'__POSTAMBLE' }
# for DIST
RAWDIR          = ../public_html/geo-wkt/raw
DISTDIR         = ../public_html/geo-wkt/source
LICENSE         = perl

# for POD
FIRST_YEAR		= 2008
EMAIL			= markov@cpan.org
WEBSITE			= http://perl.overmeer.net/CPAN/
__POSTAMBLE
