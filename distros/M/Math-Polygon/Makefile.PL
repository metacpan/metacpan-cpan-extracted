use ExtUtils::MakeMaker;

require 5.010;

WriteMakefile
  ( NAME        => 'Math::Polygon'
  , VERSION     => '1.10'
  , PREREQ_PM   =>
     { Test::More    => 0.47
     , Scalar::Util  => 1.13
     , Math::Trig    => 0
     }
  , AUTHOR      => 'Mark Overmeer'
  , ABSTRACT    => 'basic polygon calculations'
  , LICENSE     => 'perl'
  );

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
RAWDIR          = ../public_html/math-polygon/raw
DISTDIR         = ../public_html/math-polygon/source

# for POD
FIRST_YEAR      = 2004
EMAIL           = markov@cpan.org
WEBSITE         = http://perl.overmeer.net/CPAN/
__POSTAMBLE
