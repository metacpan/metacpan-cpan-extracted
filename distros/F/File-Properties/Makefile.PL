use 5.005;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'File::Properties',
    'VERSION_FROM'      => 'lib/File/Properties.pm',
    'ABSTRACT_FROM'     => 'lib/File/Properties.pm',
    'AUTHOR'            => 'Brendt Wohlberg <wohl@cpan.org>',
    'PREREQ_PM'         => {Error => 0,
			    DBI => 0,
			    DBD::SQLite => 0,
			    Cwd => 0,
			    File::stat => 0,
			    Fcntl => 0,
			    File::Type => 0,
			    File::Basename => 0,
			    Digest::SHA => 0,
			    IO::File => 0,
			    File::Temp => 0,
			    Compress::Bzip2 => 0,
			    Compress::Zlib => 0,
			    Storable => 0,
			    Image::ExifTool => 0,
			    Image::Magick => 0,
			    Time::HiRes => 0,
			    Test::More => 0},
    'NO_META'           => 1
);
