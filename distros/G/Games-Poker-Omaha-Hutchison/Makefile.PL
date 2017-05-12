use ExtUtils::MakeMaker;
WriteMakefile(
	AUTHOR        => 'Tony Bowden <kasei@tmtm.com>',
	NAME          => 'Games::Poker::Omaha::Hutchison',
	ABSTRACT_FROM => 'lib/Games/Poker/Omaha/Hutchison.pm',
	VERSION_FROM  => 'lib/Games/Poker/Omaha/Hutchison.pm',
	PREREQ_PM     => {
		'List::Util'   => 0,
		'Object::Attribute::Cached' => 0,
		'Test::More'   => 0.11,
	},
);
