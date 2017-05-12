use 5.006001;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME	     => 'Geo::OSM::Tiles',
    ABSTRACT_FROM    => 'lib/Geo/OSM/Tiles.pm', 
    AUTHOR	     => 'Rolf Krahl <rotkraut@cpan.org>', 
    VERSION_FROM     => 'lib/Geo/OSM/Tiles.pm', 
    LICENSE	     => 'perl', 
    PREREQ_PM	     => { 
	# Needed by the module Geo::OSM::Tiles
	Math::Trig     => 0,
	# Needed by the script downloadosmtiles.pl
	LWP	       => 0, 
	Getopt::Long   => 0,
	YAML	       => 0,
	File::Path     => 0,
	File::Basename => 0,
	File::Spec     => 0,
	Cwd	       => 0,
	# Needed by the test suite
	Test::More     => 0,
	File::Temp     => 0,
	File::Find     => 0,
    }, 
    EXE_FILES	     => [ 'downloadosmtiles.pl' ],
    PM		     => { 'lib/Geo/OSM/Tiles.pm' => '$(INST_LIBDIR)/Tiles.pm'}, 
    (MM->can('signature_target') ? (SIGN => 1) : ()),
);

