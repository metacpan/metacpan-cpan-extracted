use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'File::Searcher',
    'VERSION_FROM'	=> 'Searcher.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    'dist'        => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    'PREREQ_PM'    => {
	                 'File::Find' => 0,
	                 'File::Copy' => 0,
	                 'File::Flock' => 0,
	                 'Class::Struct' => 0,
	                 'Class::Generate' => 0,
	                 'Archive::Tar' => 0,
	                 'Cwd' => 0,
                     'Carp' => 0,
                     'UNIVERSAL' => 0,
		      },
);
