use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'	   => 'Image::Filter::Sharpen',    # Name of package
    'VERSION_FROM' => 'Sharpen.pm', # finds $VERSION
    'LIBS'	   => ['-L/usr/lib -lgd -ljpeg -lpng'],     # All custom libraries to be linked with
    'OBJECT' => 'sharpen.o Sharpen.o', # All object files
);

