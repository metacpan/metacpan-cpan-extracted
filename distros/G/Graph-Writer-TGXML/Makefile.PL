use ExtUtils::MakeMaker;


&WriteMakefile(
                NAME         => 'Graph-Writer-TGXML',
                DISTNAME     => 'Graph-Writer-TGXML',
                VERSION      => '0.01',
                PREREQ_PM    => {
                                 'Graph'        => 0,
                                 'XML::Writer'  => 0,
                                },
                dist         => {COMPRESS => 'gzip', SUFFIX => 'gz'},
              );

