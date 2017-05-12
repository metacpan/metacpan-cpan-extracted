use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    NAME		=> 'Mac::AppleScript::Glue',
    VERSION_FROM	=> 'Glue.pm',           # finds $VERSION
    PREREQ_PM		=> {                    # e.g., Module::Name => 1.1
        'Test::Pod' => 0,
        'Carp' => 0,
        'Data::Dumper' => 0,
        'IO::File' => 0,
        'Text::ParseWords' => 0,
        'Mac::AppleScript' => 0.03,
    },
);
