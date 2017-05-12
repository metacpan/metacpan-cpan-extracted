use 5.008001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'IPC::ConcurrencyLimit::Lock::NFS',
    VERSION_FROM      => 'lib/IPC/ConcurrencyLimit/Lock/NFS.pm', # finds $VERSION
    PREREQ_PM         => {
      'Carp' => '0',
      'File::Path' => '0',
      'File::Temp' => '0',
      'Fcntl' => '0',
      'File::SharedNFSLock' => '0.03',
      'IPC::ConcurrencyLimit' => '0.01',
      'IPC::ConcurrencyLimit::Lock' => '0',
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/IPC/ConcurrencyLimit/Lock/NFS.pm', # retrieve abstract from module
       AUTHOR         => 'Steffen Mueller <smueller@cpan.org>') : ()),
);
