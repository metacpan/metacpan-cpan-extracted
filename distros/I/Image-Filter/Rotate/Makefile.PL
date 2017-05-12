use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'	   => 'Image::Filter::Rotate',    # Name of package
    'VERSION_FROM' => 'Rotate.pm', # finds $VERSION
    'LIBS'	   => ['-L/usr/lib -lgd -ljpeg -lpng'],     # All custom libraries to be linked with
    'OBJECT' => 'rotate.o Rotate.o', # All object files
);

