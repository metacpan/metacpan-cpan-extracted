# Makefile.PL for VRML::OpenGL module.

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME => 'VRML::OpenGL',
    
    LIBS      => $VRML_CONFIG{OPENGL_LIBS},

    DEFINE => $VRML_CONFIG{OPENGL_DEFINE},
    INC => $VRML_CONFIG{OPENGL_INC},
);

