use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'FormValidator::Simple::ProfileManager::YAML',
    'VERSION_FROM' => 'lib/FormValidator/Simple/ProfileManager/YAML.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
    YAML => 0.58,
    },
);
