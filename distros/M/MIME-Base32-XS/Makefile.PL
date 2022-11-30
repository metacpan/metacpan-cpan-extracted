use 5.008005;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'MIME::Base32::XS',
    ABSTRACT         => 'MIME::Base32::XS - Encoding and decoding Base32',
    VERSION_FROM     => 'lib/MIME/Base32/XS.pm',
    AUTHOR           => 'Lucas Tiago de Moraes <lucastiagodemoraes@gmail.com>',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.008005',
    
    META_MERGE => {
        'meta-spec' => {
          version => 2,
        },
     
        resources => {
            homepage => 'https://github.com/lucas1/MIME-Base32-XS',
       
            bugtracker => {
                web => 'https://github.com/lucas1/MIME-Base32-XS/issues'
            },
       
            repository => {
                type => 'git',
                url  => 'git@github.com:lucas1/MIME-Base32-XS.git',
                web  => 'https://github.com/lucas1/MIME-Base32-XS'
            }
        }        
    },
    
    PREREQ_PM => {
        'XSLoader' => '0.24',
        'Exporter' => 0
    },
    
    test => {
        TESTS => 't/*.t'
    }     
);
