use ExtUtils::MakeMaker;


WriteMakefile(
    NAME              => 'Math::BivariateCDF',
    VERSION_FROM      => 'lib/Math/BivariateCDF.pm',
    CONFIGURE_REQUIRES => {
                "ExtUtils::MakeMaker" => 0,
    },
    TEST_REQUIRES => {
                'Test::More'      => 0,
                'Test::Warnings'  => 0,
    },
    PREREQ_PM => {
                "ExtUtils::MakeMaker" => 0,
                'Test::More'          => 0,
    },
    ($] >= 5.005 ?     
      (ABSTRACT_FROM  => 'lib/Math/BivariateCDF.pm', 
       AUTHOR         => 'Binary.com <support@binary.com>') : ()),
    LIBS              => ['-lm'], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
    OBJECT            => '$(O_FILES)', # link all the C files too
);

