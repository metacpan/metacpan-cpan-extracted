use ExtUtils::MakeMaker;

use 5.008;

my $version = '0.16';

my %prereq  =
  ( XML::Compile         => '1.28'
  , XML::Compile::Tester => '0.04'
  , XML::Compile::Cache  => '0.995'
  , Log::Report          => '0.19'
 
  , Test::More           => '0.54'
  , Test::Pod            => '1.00'
  );

# Upgrade Geo::Point only if installed, to avoid difficult indirect
# installation of Geo::Proj4
eval "require Geo::Point";
if($@ && $@ =~ m/^Can't locate /)
{   print "optional Geo::Point is not installed\n";
}
else
{   $prereq{'Geo::Point'} = '0.90';
}

WriteMakefile
  ( NAME      => 'Geo::GML'
  , VERSION   => $version
  , PREREQ_PM => \%prereq
  , EXE_FILES => []
  , AUTHOR    => 'Mark Overmeer'
  , ABSTRACT  => 'Process Geography Markup Language'
  , LICENSE   => 'perl'
  );

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
RAWDIR          = ../public_html/geo-gml/raw
DISTDIR         = ../public_html/geo-gml/source
LICENSE         = artistic

EXTENDS		= ../XMLCache:../XMLCompile

# for POD
FIRST_YEAR      = 2008
EMAIL           = perl@overmeer.net
WEBSITE         = http://perl.overmeer.net/geo/
PODTAIL		= ../Geo-ogc-podtail
__POSTAMBLE
