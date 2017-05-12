use ExtUtils::MakeMaker;
WriteMakefile(
	NAME          => 'Finance::Bank::BNPParibas',
	VERSION_FROM  => 'lib/Finance/Bank/BNPParibas.pm',
	PREREQ_PM     => { 
		'WWW::Mechanize' => 0.40,
		'Carp'           => 0,		# Core
	},
	ABSTRACT_FROM => 'lib/Finance/Bank/BNPParibas.pm',
	AUTHOR        => 'Briac Pilpré <briac@cpan.org>',
);
