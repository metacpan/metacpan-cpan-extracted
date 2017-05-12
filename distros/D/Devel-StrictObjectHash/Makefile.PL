use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Devel::StrictObjectHash',
    'VERSION_FROM'	=> 'lib/Devel/StrictObjectHash.pm', # finds $VERSION
    'PREREQ_PM'		=> {
        "Test::More" => 0.47
        }, # e.g., Module::Name => 1.1
);
