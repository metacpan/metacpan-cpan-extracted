use ExtUtils::MakeMaker;

# REQUIRES Freetype library or -lttf.

# Add several possible places for -L. 

WriteMakefile(
	NAME => 'VRML::Text',
	VERSION => '0.01',
    LIBS      => $VRML_CONFIG{FREETYPE_LIBS},

    DEFINE => $VRML_CONFIG{FREETYPE_DEFINE}." ".$VRML_CONFIG{OPENGL_DEFINE},
    INC => $VRML_CONFIG{FREETYPE_INC}." ".$VRML_CONFIG{OPENGL_INC},
);

#
#      ['-L/usr/X11R6/lib -L/usr/lib/mesa/ -lGL -lGLU -lMesaGL -lMesaGLU -lXext -lX11 '],
#

