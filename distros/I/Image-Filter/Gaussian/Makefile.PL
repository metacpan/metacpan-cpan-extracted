use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'	   => 'Image::Filter::Gaussian',    # Name of package
    'VERSION_FROM' => 'Gaussian.pm', # finds $VERSION
    'LIBS'	   => ['-L/usr/lib -lgd -ljpeg -lpng -lm'],     # All custom libraries to be linked with
    'OBJECT' => 'gaussian.o Gaussian.o', # All object files
);

