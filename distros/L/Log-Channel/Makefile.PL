use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Log::Channel',
    'VERSION_FROM'	=> 'Channel.pm', # finds $VERSION
    'PREREQ_PM'		=> {
			    Log::Dispatch => 2.01,
			    Log::Dispatch::Config => 1.01,
			    XML::Simple => 1.08,
			   }, # e.g., Module::Name => 1.1
);
