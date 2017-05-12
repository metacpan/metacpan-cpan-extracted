use 5.012000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Math::Geometry::Planar::GPC::PolygonXS',
    VERSION_FROM      => 'lib/Math/Geometry/Planar/GPC/PolygonXS.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Math/Geometry/Planar/GPC/PolygonXS.pm', # retrieve abstract from module
       AUTHOR         => 'Eric L. Wilhelm / transalted to XS by Alexei Kasatkin') : ()),
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    OBJECT            => 'PolygonXS.o functions.o gpc.o', # link all the C files too
);
