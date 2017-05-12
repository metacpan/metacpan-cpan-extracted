use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Mail::Box::MH::Resource',
    'VERSION_FROM'	=> 'Resource.pm', # finds $VERSION
    'PREREQ_PM'		=> {
			    'Mail::Reporter'=>0,
			    'File::Spec'=>0,
			   }, # e.g., Module::Name => 1.1
);
