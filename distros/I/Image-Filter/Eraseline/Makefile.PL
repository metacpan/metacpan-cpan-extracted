use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'	   => 'Image::Filter::Eraseline',    # Name of package
    'VERSION_FROM' => 'Eraseline.pm', # finds $VERSION
    'LIBS'	   => ['-L/usr/lib -lgd -ljpeg -lpng'],     # All custom libraries to be linked with
    'OBJECT' => 'eraseline.o Eraseline.o', # All object files
);

