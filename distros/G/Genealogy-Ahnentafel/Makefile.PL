use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Genealogy::Ahnentafel',
    VERSION_FROM      => 'lib/Genealogy/Ahnentafel.pm',
    PREREQ_PM         => {
        Moo                  => 0,
        MooX::ClassAttribute => 0,
        Types::Standard      => 0,
        Type::Utils          => 0,
    },
    BUILD_REQUIRES    => {
        Test::Exception      => 0,
    },
    ABSTRACT_FROM     => 'lib/Genealogy/Ahnentafel.pm',
    AUTHOR            => 'Dave Cross <dave@perlhacks.com>',
    LICENSE           => 'perl',
    MIN_PERL_VERSION  => '5.6.0',
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url => 'git://github.com/davorg/genealogy-ahnentafel.git',
                web => 'https://github.com/davorg/genealogy-ahnentafel',
            },
        },
    },
);
