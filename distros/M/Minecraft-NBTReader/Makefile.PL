use 5.016;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Minecraft::NBTReader',
    VERSION_FROM      => 'lib/Minecraft/NBTReader.pm', # finds $VERSION
    PREREQ_PM         => {
        Config => 0,
        "IO::Uncompress::Gunzip" => 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Minecraft/NBTReader.pm', # retrieve abstract from module
       AUTHOR         => 'Rene Schickbauer <cavac@cpan.org>') : ()),
);
