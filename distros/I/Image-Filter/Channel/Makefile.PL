use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'	   => 'Image::Filter::Channel',    # Name of package
    'VERSION_FROM' => 'Channel.pm', # finds $VERSION
    'LIBS'	   => ['-L/usr/lib -lgd -ljpeg -lpng'],     # All custom libraries to be linked with
    'OBJECT' => 'channel.o Channel.o', # All object files
);

