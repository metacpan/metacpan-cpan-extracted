use 5.008008;
use ExtUtils::MakeMaker;

my $preop =
    'perldoc -uT $(VERSION_FROM) | tee $(DISTVNAME)/README.pod > README.pod;' .
    'pod2text README.pod | tee $(DISTVNAME)/README > README';

WriteMakefile(
    NAME              => 'Digest::Guava',
    VERSION_FROM      => 'lib/Digest/Guava.pm',
    PREREQ_PM         => {},
    BUILD_REQUIRES    => {
        'Test::More'      => 0,
        'JSON::XS'        => 0,
        'FindBin'         => 0,
        'Data::Dumper'    => 0,
    },

    ABSTRACT_FROM     => 'lib/Digest/Guava.pm',
    AUTHOR            => 'igorcoding <igorcoding@gmail.com>',
    LICENSE           => 'perl',
    LIBS              => [''],
    DEFINE            => '-g -ggdb -O0 -std=c99 -Wall',
    INC               => '-I.',
    dist              => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', PREOP => $preop },
);
