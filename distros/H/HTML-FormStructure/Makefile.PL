use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'HTML::FormStructure',
    'VERSION_FROM' => 'lib/HTML/FormStructure.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
	Class::Accessor => 0.18
    },
);
