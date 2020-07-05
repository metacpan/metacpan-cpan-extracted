use ExtUtils::MakeMaker;
WriteMakefile(
	"NAME" => "IO::File::Multi"
	, "LICENSE" => "perl",
	, "DISTNAME" => "Multi"
	, "VERSION_FROM" => "lib/IO/File/Multi.pm"
	, "PREREQ_PM" => {
		"IO::File" => 0
	}
	, "TEST_REQUIRES" => {
		"File::Temp" => 0
	}
);
