use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'               => 'IO::Socket::Socks',
    'LICENSE'            => 'lgpl',
    'PREREQ_PM'          => { 'Socket' => 1.94, 'IO::Select' => 0, 'constant' => 1.03 },
    'BUILD_REQUIRES'     => { 'Test::More' => 0.88 },
    'CONFIGURE_REQUIRES' => { 'ExtUtils::MakeMaker' => 6.52 },
    'META_MERGE' => { resources => {repository => 'https://github.com/olegwtf/p5-IO-Socket-Socks'} },
    'VERSION_FROM'  => 'lib/IO/Socket/Socks.pm',
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/IO/Socket/Socks.pm', # retrieve abstract from module
       AUTHOR         => 'Oleg G <oleg@cpan.org>') : ()),
    'dist' => {
        'COMPRESS' => 'gzip --best'
    }
);
