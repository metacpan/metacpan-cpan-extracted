use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Encode::Detect::Upload',
    AUTHOR              => q{Lyle Hopkins <webmaster@cosmicperl.com>},
    VERSION_FROM        => 'lib/Encode/Detect/Upload.pm',
    ABSTRACT_FROM       => 'lib/Encode/Detect/Upload.pm',
    ($ExtUtils::MakeMaker::VERSION ge 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'        => 0,
        'Test::Exception'	=> 0,
        'Test::NoWarnings'	=> 0,
        'Encode'	        => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Encode-Detect-Upload-*' },
);
