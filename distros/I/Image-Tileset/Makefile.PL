use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Image::Tileset',
    VERSION_FROM      => 'lib/Image/Tileset.pm', # finds $VERSION
    PREREQ_PM         => {
	'Image::Magick' => 1,
	'XML::Simple'   => 1,
	}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Image/Tileset.pm', # retrieve abstract from module
       AUTHOR         => 'Noah Petherbridge <root@kirsle.net>') : ()),
);
