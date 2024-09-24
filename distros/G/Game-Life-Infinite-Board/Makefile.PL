use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'Game::Life::Infinite::Board',
    VERSION_FROM    => 'lib/Game/Life/Infinite/Board.pm',
    PREREQ_PM => {
    	# Require Time::HiRes at least 1.9719 
    	"Time::HiRes" => "1.9719",
	},
    MIN_PERL_VERSION => '5.10.1',
    LICENSE => 'perl_5',
);
