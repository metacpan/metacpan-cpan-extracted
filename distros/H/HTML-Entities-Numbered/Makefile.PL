use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'HTML::Entities::Numbered',
    VERSION_FROM => 'lib/HTML/Entities/Numbered.pm', # finds $VERSION
    PREREQ_PM    => {
	'Test::More'     => 0.32,
    },
);
