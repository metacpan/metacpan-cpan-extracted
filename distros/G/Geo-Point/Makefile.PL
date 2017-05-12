use ExtUtils::MakeMaker;

require 5.008;

WriteMakefile
  ( NAME        => 'Geo::Point'
  , VERSION     => '0.96'
  , PREREQ_PM   =>
     { Test::More    => 0.47
     , Geo::Distance => 0.06
     , Geo::Proj4    => 1.01
     , Math::Polygon => 1.01
     , Math::Trig    => 1.00
     }
  , AUTHOR      => 'Mark Overmeer'
  , ABSTRACT    => 'Geographical structures'
  , LICENSE     => 'perl'
  );

#### the next lines are added for OODoc, which generates the
#### distribution.
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
RAWDIR          = ../public_html/geopoint/raw
DISTDIR         = ../public_html/geopoint/source
LICENSE         = artistic

# for POD
FIRST_YEAR      = 2005
EMAIL           = perl@overmeer.net
WEBSITE         = http://perl.overmeer.net/geo/

# for HTML
EXTENDS		= ../MathPolygon:../GeoProj4:../GeoWKT:../GeoGML:../Geo139:../GeoEOP:../XMLCompile:../XMLCache:../Envisat:../Landsat:../DBD-mysql-Geom
HTML_OUTPUT     = ../public_html/geo/html
HTML_DOCROOT    = /geo/html
HTML_PACKAGE    = ../public_html/geo/htmlpkg

PODTAIL         = ../Geo-shared-podtail
__POSTAMBLE

