use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
chomp($machine=`uname -m`);
$machine =~ s#\W#_#;

WriteMakefile(
    NAME              => 'Games::Hack::Live',
    VERSION_FROM      => 'lib/Games/Hack/Live.pm', # finds $VERSION
    PREREQ_PM         => { Expect => 1.21, 
			IPC::Mmap => 0.21, # for testing only
			"Games::Hack::Patch::$machine" => 0 },
	depend => { 
		'hack-live'			=> "t/test-double t/test-long",
		"t/test-double" 	=> "t/test-double.c", 
		"t/test-long" 		=> "t/test-long.c", 
	},
    EXE_FILES         => [ "hack-live" ],
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Games/Hack/Live.pm', # retrieve abstract from module
       AUTHOR         => 'Ph. Marek <pmarek@cpan.org>') : ()),
);
