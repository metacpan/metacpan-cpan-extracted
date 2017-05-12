use ExtUtils::MakeMaker;

require 5.006;

WriteMakefile
  ( NAME      => 'Geo::WKT'
  , VERSION   => '0.95'
  , AUTHOR    => 'Mark Overmeer'
  , ABSTRACT  => 'Geometry in wellknown text format'

  , PREREQ_PM =>
     { Geo::Point    => 0.91
     , Test::More    => 0.47
     }
  );

sub MY::postamble { <<'__POSTAMBLE' }
# for DIST
RAWDIR          = ../public_html/geowkt/raw
DISTDIR         = ../public_html/geowkt/source
LICENSE         = artistic

# for POD
FIRST_YEAR	= 2008
EMAIL		= perl@overmeer.net
WEBSITE		= http://perl.overmeer.net/geo
PODTAIL         = ../Geo-shared-podtail
__POSTAMBLE
