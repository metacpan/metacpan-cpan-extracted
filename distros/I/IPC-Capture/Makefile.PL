use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'IPC::Capture',
    VERSION_FROM      => 'lib/IPC/Capture.pm', # finds $VERSION
    PREREQ_PM         => {  IPC::Cmd          => 0,
                            Class::Base       => 0,
                            Test::Differences => 0,
                            Text::Diff        => 0.34,
                            Carp              => 0,
                            Data::Dumper      => 0,
                            Env               => 0,
                            File::Basename    => 0,
                            File::Path        => 0,
                            File::Spec        => 0,
                            File::Temp        => 0,
                            FindBin           => 0,
                            Hash::Util        => 0,
                            List::MoreUtils   => 0,
                            List::Util        => 0,
                            Test::More        => 0,
                            strict            => 0,
                            warnings          => 0,
                         }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/IPC/Capture.pm', # retrieve abstract from module
       AUTHOR         => 'Joseph Brenner <doom@>') : ()),
);
