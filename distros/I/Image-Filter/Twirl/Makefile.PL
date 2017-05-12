use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'	   => 'Image::Filter::Twirl',    # Name of package
    'VERSION_FROM' => 'Twirl.pm', # finds $VERSION
    'LIBS'	   => ['-L/usr/lib -lgd -ljpeg -lpng -lm'],     # All custom libraries to be linked with
    'OBJECT' => 'twirl.o Twirl.o', # All object files
);

