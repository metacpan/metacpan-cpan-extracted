use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME               => 'IO::Socket::Socks::Wrapper',
    LICENSE            => 'perl',
    VERSION_FROM       => 'lib/IO/Socket/Socks/Wrapper.pm',
    PREREQ_PM          => { IO::Socket::Socks => 0.73 }, # e.g., Module::Name => 1.1,
    BUILD_REQUIRES     => { Test::More => 0.88 },
    CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => 6.52 },
    META_MERGE         => { resources => {repository => 'https://github.com/olegwtf/p5-IO-Socket-Socks-Wrapper'} },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM   => 'lib/IO/Socket/Socks/Wrapper.pm', # retrieve abstract from module
       AUTHOR          => 'Oleg G <oleg@cpan.org>') : ()),
);
