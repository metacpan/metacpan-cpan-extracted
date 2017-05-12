use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Email::Valid::Loose',
    'VERSION_FROM' => 'lib/Email/Valid/Loose.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
	Email::Valid => 0.17,
    },
);
