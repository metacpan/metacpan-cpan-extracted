use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Device::KeyStroke::Mobile',
    'VERSION_FROM' => 'lib/Device/KeyStroke/Mobile.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
    },
);
