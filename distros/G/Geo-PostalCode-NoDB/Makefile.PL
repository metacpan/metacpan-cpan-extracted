use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'         => 'Geo::PostalCode::NoDB',
    'VERSION_FROM' => 'lib/Geo/PostalCode/NoDB.pm',    # finds $VERSION
    'INST_SCRIPT'  => 'script',
    'PREREQ_PM'    => {
        Test::More       => 0,
        File::Spec       => 0,
        FileHandle       => 0,
        Archive::Extract => 0,
        Archive::Zip     => 0,
        File::Slurp      => 0,
        Digest::MD5      => 0,
        List::MoreUtils  => 0,
    },
);
