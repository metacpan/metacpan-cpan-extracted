use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Geo::PostalCode',
    'VERSION_FROM' => 'lib/Geo/PostalCode.pm', # finds $VERSION
    'INST_SCRIPT' => 'script',
    'PREREQ_PM' => {
        Test::More 	=> 0,
        File::Spec	=> 0,
        FileHandle	=> 0,
    },
);
