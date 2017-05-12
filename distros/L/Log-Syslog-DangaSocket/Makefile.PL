use 5.008005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Log::Syslog::DangaSocket',
    VERSION_FROM      => 'lib/Log/Syslog/DangaSocket.pm', # finds $VERSION
    PREREQ_PM         => {
        'Danga::Socket' => 1.59,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Log/Syslog/DangaSocket.pm', # retrieve abstract from module
       AUTHOR         => 'Adam Thomason <athomason@cpan.org>') : ()),
);
