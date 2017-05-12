use 5.008004;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Math::Assistant',
    VERSION_FROM      => 'lib/Math/Assistant.pm',
    LICENSE           => 'perl',
    PREREQ_PM         => {
            'Math::BigInt'	=> '1.997',
            'Math::BigFloat'	=> '1.997',
            'Carp'		=> '0',
            'Test::More'	=> '0.98',
    },
    dist => {
        COMPRESS => 'gzip -9f',
        SUFFIX => 'gz',
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Math/Assistant.pm',
       AUTHOR         => 'Alessandro Gorohovski <an.gorohovski@gmail.com>') : ()),
);
