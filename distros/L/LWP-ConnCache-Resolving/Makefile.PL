use 5.008004;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'LWP::ConnCache::Resolving',
    VERSION_FROM      => 'lib/LWP/ConnCache/Resolving.pm', # finds $VERSION
    PREREQ_PM         => { 'LWP::ConnCache' => '0.01' }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/LWP/ConnCache/Resolving.pm', # retrieve abstract from module
       AUTHOR         => 'Sergey Chernyshev <sergeyche@cpan.org>') : ()),
);
