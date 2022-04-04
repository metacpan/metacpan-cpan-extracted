use ExtUtils::MakeMaker;

WriteMakefile(
    NAME	    => 'Graphics::Fig',
    VERSION_FROM    => 'lib/Graphics/Fig.pm',
    ABSTRACT_FROM   => 'lib/Graphics/Fig.pm',
    AUTHOR	    => 'Scott Guthridge <scott_guthridge@rompromity.net>',
    BUILD_REQUIRES  => {
	File::Temp		=> 0.2300,
	Test::More		=> 1.0
    },
    LICENSE	    => 'artistic_2',
    PREREQ_PM	    => {
	Image::Info		=> 1.37,
	Math::Trig		=> 1.0,
	Graphics::ColorNames	=> 'v3.5.0',
    },
);
