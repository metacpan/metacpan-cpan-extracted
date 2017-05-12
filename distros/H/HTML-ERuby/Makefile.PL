use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'HTML::ERuby',
    'VERSION_FROM' => 'lib/HTML/ERuby.pm', # finds $VERSION
    'PREREQ_PM' => {
	Inline::Ruby => 0,
	Test::More => 0.32,
    },
);
