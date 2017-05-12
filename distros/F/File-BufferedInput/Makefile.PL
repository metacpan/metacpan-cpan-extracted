use ExtUtils::MakeMaker;
# See lib/ExtUtils/BufferedInput.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'File::BufferedInput',
    VERSION_FROM      => 'lib/File/BufferedInput.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/File/BufferedInput.pm', # retrieve abstract from module
       AUTHOR         => 'Ahmed Amin ELsheshtawy <support@mewsoft.com>') : ()),
);
