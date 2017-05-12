use 5.006;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'File::Finder',
    VERSION_FROM      => 'lib/File/Finder.pm', # finds $VERSION
    PREREQ_PM         => {
			  "Text::Glob" => 0,
			  "Test::More" => 0,
			 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/File/Finder.pm', # retrieve abstract from module
       AUTHOR         => 'Randal L. Schwartz <merlyn@stonehenge.com>') : ()),
);
