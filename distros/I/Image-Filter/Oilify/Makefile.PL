use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'	   => 'Image::Filter::Oilify',    # Name of package
    'VERSION_FROM' => 'Oilify.pm', # finds $VERSION
    'LIBS'	   => ['-L/usr/lib -lgd -ljpeg -lpng -lm'],     # All custom libraries to be linked with
    'OBJECT' => 'oilify.o Oilify.o', # All object files
);

