use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Image::XFace',
    'VERSION_FROM' => 'XFace.pm',
    'LIBS'	=> ['-lcompface'],
    'OBJECT'    => "faces.o faces_wrap.o"
);
