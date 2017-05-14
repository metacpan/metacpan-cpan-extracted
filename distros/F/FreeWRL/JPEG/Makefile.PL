use ExtUtils::MakeMaker;

# Add several possible places for -L. 

WriteMakefile(
	NAME => 'VRML::JPEG',
    LIBS      => $VRML_CONFIG{JPEG_LIBS},

    DEFINE => $VRML_CONFIG{JPEG_DEFINE},
    INC => $VRML_CONFIG{JPEG_INC},
);


