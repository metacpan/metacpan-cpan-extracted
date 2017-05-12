use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Document::Info',
    'VERSION_FROM' => 'Info.pm', # finds $VERSION
    'dist'  => {
        "COMPRESS" => "gzip",
        "SUFFIX"   => "gz"
    },
    "EXE_FILES" => [
        "lfile"
    ],
);
