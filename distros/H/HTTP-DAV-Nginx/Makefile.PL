use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'HTTP::DAV::Nginx',
    VERSION_FROM      => 'lib/HTTP/DAV/Nginx.pm', # finds $VERSION
    PREREQ_PM         => {'LWP::UserAgent' => 0}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/HTTP/DAV/Nginx.pm', # retrieve abstract from module
       AUTHOR         => 'Dmitry Kosenkov <d.kosenkov@rambler-co.ru>') : ()),
);
