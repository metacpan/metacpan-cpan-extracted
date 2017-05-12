use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'	   => 'Image::Filter::Swirl',    # Name of package
    'VERSION_FROM' => 'Swirl.pm', # finds $VERSION
    'LIBS'	   => ['-L/usr/lib -lgd -ljpeg -lpng -lm'],     # All custom libraries to be linked with
    'OBJECT' => 'swirl.o Swirl.o', # All object files
);

