use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'File::Searcher::Interactive',
    'VERSION_FROM'	=> 'Interactive.pm', # finds $VERSION
	'dist'        => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    'PREREQ_PM'		=> {
    				'File::Searcher' => 0,
    				'Term::Prompt' => 0,
    				'Term::ANSIColor' => 0
    	}, # e.g., Module::Name => 1.1
);
