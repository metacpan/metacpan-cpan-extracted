use ExtUtils::MakeMaker;

require 5.008;

WriteMakefile
  ( NAME        => 'Geo::Point'
  , VERSION     => '0.99'
  , PREREQ_PM   =>
     { Test::More    => 0.47
     , GIS::Distance => 0.14
     , Geo::Proj4    => 1.01
     , Math::Polygon => 1.01
     , Math::Trig    => 1.00
     }
  , AUTHOR      => 'Mark Overmeer'
  , ABSTRACT    => 'Geographical structures'
  , LICENSE     => 'perl_5'

  , META_MERGE =>
      { 'meta-spec' => { version => 2 }
      , resources  =>
          { repository =>
              { type => 'git'
              , url  => 'https://github.com/markov2/perl5-Geo-Point.git'
              , web  => 'https://github.com/markov2/perl5-Geo-Point'
              }
          , homepage => 'http://perl.overmeer.net/CPAN/'
          , license  => [ 'http://dev.perl.org/licenses/' ]
          }
      }
  );

#### the next lines are added for OODoc, which generates the
#### distribution.
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
RAWDIR          = ../public_html/geo-point/raw
DISTDIR         = ../public_html/geo-point/source
LICENSE         = perl

# for POD
FIRST_YEAR      = 2005
EMAIL           = markov@cpan.org
WEBSITE         = http://perl.overmeer.net/CPAN/

# To be able to load Proj4
#LD_LIBRARY_PATH = ../Geo-Proj4/blib

# for HTML
EXTENDS		= ../Geo-Proj4:../Geo-WKT:../Geo-GML:../Geo-ISO19139:/p/GeoEOP:../XML-Compile:../XML-Compile-Cache:../Geo-Format-Envisat:../Geo-Format-Landsat:/p/DBD-mysql-Geom:../Geo-WKT:../Math-Polygon
HTML_OUTPUT     = ../public_html/geo/html
HTML_DOCROOT    = /geo/html
HTML_PACKAGE    = ../public_html/geo-point/htmlpkg

__POSTAMBLE

