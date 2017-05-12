use ExtUtils::MakeMaker;

require 5.008;

WriteMakefile
  ( NAME        => 'Geo::Format::Landsat'
  , VERSION     => '0.03'
  , PREREQ_PM   =>
     { Test::More     => 0.47
     , Geo::Point     => 0.90
     , Geo::Proj4     => 1.01
     }
  , AUTHOR      => 'Mark Overmeer'
  , ABSTRACT    => 'Decode Landsat meta-data'
  , LICENSE     => 'perl'
  );

#### the next lines are added for OODoc, which generates the
#### distribution.
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
RAWDIR          = ../public_html/geo-format-landsat/raw
DISTDIR         = ../public_html/geo-format-landsat/source
LICENSE         = artistic

# for POD
FIRST_YEAR      = 2009
EMAIL           = perl@overmeer.net
WEBSITE         = http://perl.overmeer.net/geo/

PODTAIL         = ../Geo-shared-podtail
__POSTAMBLE

