use ExtUtils::MakeMaker;

WriteMakefile(
    NAME	 => 'LWP-attic',
    VERSION      => '1.00',
    dist         => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
