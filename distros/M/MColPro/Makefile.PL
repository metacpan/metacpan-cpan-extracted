use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'MColPro',
    AUTHOR              => q{WJIAN <cloveperl@gmail.com>},
    VERSION_FROM        => 'lib/MColPro.pm',
    ABSTRACT_FROM       => 'lib/MColPro.pm',
    PREFIX              => '/opt/MColPro/',
    LIB                 => '$(PREFIX)/lib',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'DynGig::Range::String' => 1.00,
        'YAML::XS'    =>  0.38,
        'Net::MySQL'  =>  0.11,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'MColPro-*' },
);
