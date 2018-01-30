use ExtUtils::MakeMaker;

require 5.008;

WriteMakefile
  ( NAME        => 'Geo::Format::Envisat'
  , VERSION     => '0.90'
  , PREREQ_PM   =>
     { Test::More     => 0.47
     , Geo::Point     => 0.96
     , IO::Uncompress::AnyUncompress => 2.015
     , POSIX          => 0
     , File::Basename => 0
     }
  , AUTHOR      => 'Mark Overmeer'
  , ABSTRACT    => 'Decode ENVISAT and ERS1/ERS2 meta-data'
  , LICENSE     => 'perl'
  );

#### the next lines are added for OODoc, which generates the
#### distribution.
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
RAWDIR          = ../public_html/geo-format-envisat/raw
DISTDIR         = ../public_html/geo-format-envisat/source
LICENSE         = perl

# for POD
FIRST_YEAR      = 2008
EMAIL           = markov@cpan.org
WEBSITE         = http://perl.overmeer.net/CPAN/

__POSTAMBLE

