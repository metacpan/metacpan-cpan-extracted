use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Geo::IP2Proxy',
    VERSION_FROM      => 'lib/Geo/IP2Proxy.pm',
    PREREQ_PM         => {},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Geo/IP2Proxy.pm', # retrieve abstract from module
       AUTHOR         => 'IP2Location <hexasoft@gmail.com>') : ()),
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    LICENSE           => 'mit',
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	  # Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
