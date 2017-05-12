use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'	   => 'Image::Filter::Foo',    # Name of package
    'VERSION_FROM' => 'Foo.pm', # finds $VERSION
    'LIBS'	   => ['-L/usr/lib -lgd -ljpeg -lpng'],     # All custom libraries to be linked with
    'OBJECT' => 'foo.o Foo.o', # All object files
);

