use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'Graphics::Fig',
    VERSION_FROM    => 'lib/Graphics/Fig.pm',
    BUILD_REQUIRES  => {
	File::Temp 	=> 0.2300,
	Test::More 	=> 1.0,
    },
    PREREQ_PM	    => {
	Image::Info	=> 1.37,
	Math::Trig	=> 1.0,
    },
);
