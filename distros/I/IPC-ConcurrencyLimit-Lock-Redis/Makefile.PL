use 5.008001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'IPC::ConcurrencyLimit::Lock::Redis',
    VERSION_FROM      => 'lib/IPC/ConcurrencyLimit/Lock/Redis.pm', # finds $VERSION
    PREREQ_PM         => {
      'Carp' => '0',
      'IPC::ConcurrencyLimit' => '0.10',
      'IPC::ConcurrencyLimit::Lock' => '0',
      'Redis' => '1.955',
      'Redis::ScriptCache' => '0.01',
      'Class::XSAccessor' => '1.12',
      'Data::UUID::MT' => '0',
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/IPC/ConcurrencyLimit/Lock/Redis.pm', # retrieve abstract from module
       AUTHOR         => 'Steffen Mueller <smueller@cpan.org>') : ()),
);
