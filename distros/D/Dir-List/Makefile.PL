use 5.008;
use ExtUtils::MakeMaker;
WriteMakefile(
	NAME				=> 'Dir::List',
	VERSION_FROM		=> 'lib/Dir/List.pm',
	PREREQ_PM			=> {
								Cache::File => 0,
								Filesys::DiskUsage => 0,
								Clone => 0,
								File::Type => 0,
								Date::Format => 0,
								FreezeThaw => 0,
						},
	($] >= 5.005 ?
		(ABSTRACT_FROM	=> 'lib/Dir/List.pm',
		AUTHOR			=> 'Oliver Falk <oliver@linux-kernel.at>') : ()),
	dist				=> {
		COMPRESS		=> 'gzip --force --best'
	},
);
