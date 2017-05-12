use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'Gzip::BinarySearch',
    VERSION_FROM => 'lib/Gzip/BinarySearch.pm',
    DEFINE => '',
    INC => '',
    dist => {'COMPRESS'=>'gzip -9f', 'SUFFIX' => 'gz'},
    PREREQ_PM => {
        'version' => 0,
        'Test::More' => '0.47',
        'Test::Exception' => '0.22',
        'Gzip::RandomAccess' => '0.9',
    },
);

