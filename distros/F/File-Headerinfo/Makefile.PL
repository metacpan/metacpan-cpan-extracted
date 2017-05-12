use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'		=> 'File::Headerinfo',
    'VERSION_FROM'	=> 'lib/File/Headerinfo.pm', # finds $VERSION
    'PREREQ_PM'		=> {
        Video::Info => 0,
        SWF::Header => 0,
        Image::Size => 0,
        Audio::Wav => 0,
        MP3::Info => 0,
    },
);
