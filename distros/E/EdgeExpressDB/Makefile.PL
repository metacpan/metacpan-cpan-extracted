use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
 'NAME' => 'EEDB',
 'VERSION_FROM' => 'lib/EEDB.pm', # finds $VERSION
 'AUTHOR' => 'Jessica Severin <jessica.severin@gmail.com>',
 'PREREQ_PM' => {
    MQdb => 0.951,
    DBI => 1.51,
    Data::UUID => 1.148,
    XML::TreePP => 0.33,
    Time::HiRes => 1.86,
    Compress::Zlib => 2.005,
    File::Temp => 0.16,
    Getopt::Long => 2.35,
    DBD::mysql => 3.0005,
  },
);
