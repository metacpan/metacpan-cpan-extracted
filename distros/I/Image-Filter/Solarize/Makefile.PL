use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'	   => 'Image::Filter::Solarize',    # Name of package
    'VERSION_FROM' => 'Solarize.pm', # finds $VERSION
    'LIBS'	   => ['-L/usr/lib -lgd -ljpeg -lpng -lm'],     # All custom libraries to be linked with
    'OBJECT' => 'solarize.o Solarize.o', # All object files
);

