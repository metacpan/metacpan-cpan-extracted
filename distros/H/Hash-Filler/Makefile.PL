use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	      'NAME'	=> 'Hash::Filler',
	      'VERSION_FROM' => 'Filler.pm', # finds $VERSION
	      'PREREQ_PM' => { 'Time::HiRes' => 0, },
);
