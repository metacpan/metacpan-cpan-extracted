use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'	   => 'Image::Filter::Floyd',    # Name of package
    'VERSION_FROM' => 'Floyd.pm', # finds $VERSION 
    'LIBS'	   => ['-L/usr/lib -lgd -ljpeg -lpng'],     # All custom libraries to be linked with
    'OBJECT' => 'floyd.o Floyd.o', # All object files
);

