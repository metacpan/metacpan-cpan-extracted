use ExtUtils::MakeMaker;
 
WriteMakefile(
    NAME             => 'JS::AA',
    ABSTRACT         => 'Encode and Decode AA',
    AUTHOR           => 'Lucas Tiago de Moraes <lucastiagodemoraes@gmail.com>',
    VERSION_FROM     => 'lib/JS/AA.pm',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.010001',
     
    META_MERGE => {
        'meta-spec' => {
          version => 2,
        },
      
        resources => {
            homepage => 'https://github.com/lucas1/JS-AA',
        
            bugtracker => {
                web => 'https://github.com/lucas1/JS-AA/issues'
            },
        
            repository => {
                type => 'git',
                url  => 'git@github.com:lucas1/JS-AA.git',
                web  => 'https://github.com/lucas1/JS-AA'
            }
        }        
    },
     
    PREREQ_PM => {
        'Exporter' => 0,
        'Encode' => 0
    },
     
    test => {
        TESTS => 't/*.t'
    }    
);