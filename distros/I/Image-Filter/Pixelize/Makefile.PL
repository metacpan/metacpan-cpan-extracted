use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'	   => 'Image::Filter::Pixelize',    # Name of package
    'VERSION_FROM' => 'Pixelize.pm', # finds $VERSION
    'LIBS'	   => ['-L/usr/lib -lgd -ljpeg -lpng'],     # All custom libraries to be linked with
    'OBJECT' => 'pixelize.o Pixelize.o', # All object files
);

