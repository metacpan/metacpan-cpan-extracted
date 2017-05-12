use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		    => 'Linux::Svgalib',
    'VERSION_FROM'	=> 'lib/Linux/Svgalib.pm',
    'PREREQ_PM'		=> {},
    'AUTHOR'        => ['Jonathan Stowe <jns@gellyfish.co.uk>'],
    'LIBS'		    => ['-lvga'],
    'CCFLAGS'       => '-Wno-unused-label',
    'DEFINE'		=> '',
    'INC'		    => '', 
    'OBJECT'		=> '$(O_FILES)',
    'XSPROTOARG'    => '-noprototypes',
);
