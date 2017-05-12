use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'	   => 'Image::Filter::Greyscale',    # Name of package
    'VERSION_FROM' => 'Greyscale.pm', # finds $VERSION
    'LIBS'	   => ['-L/usr/lib -lgd -ljpeg -lpng'],     # All custom libraries to be linked with
    'OBJECT' => 'greyscale.o Greyscale.o', # All object files
);

