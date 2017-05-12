use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Math::Geometry::Planar',
    'VERSION_FROM'	=> 'Planar.pm', # finds $VERSION
    'PREREQ_PM'		=> {Math::Geometry::Planar::GPC=>'1.04',
                            Math::Geometry::Planar::Offset=>'1.03',
                            Carp=>'0',
                            POSIX=>'0'}, # e.g., Module::Name => 1.1
    'LIBS'		=> [''], # e.g., '-lm'
    'DEFINE'		=> '', # e.g., '-DHAVE_SOMETHING'
    'INC'		=> '', # e.g., '-I/usr/include/other'
    'AUTHOR'            => 'Danny Van de Pol (daniel.van_de_pol@alcatel.be)',
    'ABSTRACT'          => 'Planar geometry package',
);
