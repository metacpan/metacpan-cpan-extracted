use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Hash::Storage',
    AUTHOR              => q{"koorchik" <"koorchik@cpan.org">},
    VERSION_FROM        => 'lib/Hash/Storage.pm',
    ABSTRACT_FROM       => 'lib/Hash/Storage.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'       => 0,
        'Test::Deep'       => 0,
        'JSON'             => 0,
        'File::Slurp'      => 0,
        'Query::Abstract'  => 0,
        'Class::Load'      => 0,
	    'Data::Serializer' => 0.60
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Hash-Storage-*' },
);
