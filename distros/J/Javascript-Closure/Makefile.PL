use 5.008008;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Javascript::Closure',
    AUTHOR         => 'SHIRIRU <shirirulestheworld@gmail.com>',
    VERSION_FROM      => 'lib/Javascript/Closure.pm', 
    ABSTRACT_FROM     => 'lib/Javascript/Closure.pm', 
    PREREQ_PM         => {
		'LWP::UserAgent'=> '0',
		'Test::More'	=> '0'
	}
);
