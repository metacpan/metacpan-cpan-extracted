use ExtUtils::MakeMaker;

use 5.008;

WriteMakefile
  ( NAME	 => 'Hash::Case'
  , VERSION      => '1.02'
  , PREREQ_PM    =>
    { Test::More   => 0.47
    , Log::Report  => 0.26
    }
  , AUTHOR       => 'Mark Overmeer'
  , ABSTRACT     => 'Play trics with hash keys'
  , LICENSE      => 'perl'
  );

sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
RAWDIR          = ../public_html/hash-case/raw
DISTDIR         = ../public_html/hash-case/source
LICENSE         = artistic

# for POD
FIRST_YEAR      = 2002-2003,2007
EMAIL           = perl@overmeer.net
WEBSITE         = http://perl.overmeer.net/hash-case/
SKIP_LINKS	= XML::LibXML

__POSTAMBLE

