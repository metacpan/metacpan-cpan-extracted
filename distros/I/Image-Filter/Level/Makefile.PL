use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'	   => 'Image::Filter::Level',    # Name of package
    'VERSION_FROM' => 'Level.pm', # finds $VERSION
    'LIBS'	   => ['-L/usr/lib -lgd -ljpeg -lpng'],     # All custom libraries to be linked with
    'OBJECT' => 'level.o Level.o', # All object files
);

