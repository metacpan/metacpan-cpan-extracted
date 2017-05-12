use ExtUtils::MakeMaker;

require 5.006;

WriteMakefile
  ( NAME        => 'Math::Polygon'
  , VERSION     => '1.05'
  , PREREQ_PM   =>
     { Test::More    => 0.47
     , Scalar::Util  => 1.13
     , Math::Trig    => 0
     , Test::Pod     => 1.00
     }
  , AUTHOR      => 'Mark Overmeer'
  , ABSTRACT    => 'Polygon calculations'
  , LICENSE     => 'perl'
  );

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
RAWDIR          = ../public_html/polygon/raw
DISTDIR         = ../public_html/polygon/source
LICENSE         = artistic

# for POD
FIRST_YEAR      = 2004,2006
EMAIL           = perl@overmeer.net
WEBSITE         = http://perl.overmeer.net/geo/
__POSTAMBLE
