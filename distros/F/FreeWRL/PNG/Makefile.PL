use ExtUtils::MakeMaker;

# Add several possible places for -L. 

WriteMakefile(
	NAME => 'VRML::PNG',
    LIBS      => $VRML_CONFIG{PNG_LIBS},

    DEFINE => $VRML_CONFIG{PNG_DEFINE},
    INC => $VRML_CONFIG{PNG_INC},
);


