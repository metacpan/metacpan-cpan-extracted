use ExtUtils::MakeMaker;

require 5.006;

WriteMakefile
  ( NAME        => 'Math::Polygon'
  , VERSION     => '1.07'
  , PREREQ_PM   =>
     { Test::More    => 0.47
     , Scalar::Util  => 1.13
     , Math::Trig    => 0
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

# for POD
FIRST_YEAR      = 2004
EMAIL           = perl@overmeer.net
WEBSITE         = http://perl.overmeer.net/geo/
__POSTAMBLE
