use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'HTML::TagCloud::Extended',
    VERSION_FROM      => 'lib/HTML/TagCloud/Extended.pm', # finds $VERSION
    PREREQ_PM         => {
		Time::Local              => 0,
		Class::Data::Inheritable => 0,
		Class::Accessor          => 0,
		Readonly                 => 0,
	},
);
