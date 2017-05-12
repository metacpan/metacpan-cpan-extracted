use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Math::Geometry::Planar::GPC',
    'VERSION_FROM'	=> 'GPC.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    'LIBS'		=> [''], # e.g., '-lm'
    'DEFINE'		=> '', # e.g., '-DHAVE_SOMETHING'
    'INC'		=> '', # e.g., '-I/usr/include/other'
    'AUTHOR'            => 'Danny Van de Pol (daniel.van_de_pol@alcatel.be)',
    'ABSTRACT'          => 'General Polygon Clipping library wrapper',
);
