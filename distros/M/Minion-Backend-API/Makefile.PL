use ExtUtils::MakeMaker;
 
WriteMakefile(
    NAME             => 'Minion::Backend::API',
    ABSTRACT         => 'API Rest backend',
    AUTHOR           => 'Lucas Tiago de Moraes <lucastiagodemoraes@gmail.com>',
    VERSION_FROM     => 'lib/Minion/Backend/API.pm',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.010001',
     
    META_MERGE => {
        'meta-spec' => {
          version => 2,
        },
      
        resources => {
            homepage => 'https://github.com/lucas1/Minion-Backend-API',
        
            bugtracker => {
                web => 'https://github.com/lucas1/Minion-Backend-API/issues'
            },
        
            repository => {
                type => 'git',
                url  => 'git@github.com:lucas1/Minion-Backend-API.git',
                web  => 'https://github.com/lucas1/Minion-Backend-API'
            }
        }        
    },
     
    PREREQ_PM => {
        'Minion' => 0,
        'Mojolicious' => 0,
        'Carp' => 0,
    },
    
    TEST_REQUIRES => {
        'Test::More' => 0,
        'Minion' => 0,
        'Mojolicious' => 0
    },
    
    test => {
        TESTS => 't/*.t'
    }    
);