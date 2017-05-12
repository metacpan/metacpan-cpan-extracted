use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'MP3::Merge',
    VERSION_FROM      => 'lib/MP3/Merge.pm', # finds $VERSION
    PREREQ_PM         => {'MPEG::Audio::Frame' => 0.08}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/MP3/Merge.pm', # retrieve abstract from module
       AUTHOR         => 'Ahmed Amin ELsheshtawy <support@mewsoft.com>') : ()),
);
