use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	=> 'Finance::Currency::ParValueSeparate',
    'VERSION_FROM' => 'ParValueSeparate.pm', # finds $VERSION
    'DISTNAME'     => 'Finance-Currency-ParValueSeparate',
    'dist'         => {
        'COMPRESS' => 'gzip',
        'SUFFIX'   => 'gz',
    },
);
