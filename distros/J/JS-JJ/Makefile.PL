use ExtUtils::MakeMaker;
 
WriteMakefile(
    NAME             => 'JS::JJ',
    ABSTRACT         => 'Encode and Decode JJ',
    AUTHOR           => 'Lucas Tiago de Moraes <lucastiagodemoraes@gmail.com>',
    VERSION_FROM     => 'lib/JS/JJ.pm',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.010001',
     
    META_MERGE => {
        'meta-spec' => {
          version => 2,
        },
      
        resources => {
            homepage => 'https://github.com/lucas1/JS-JJ',
        
            bugtracker => {
                web => 'https://github.com/lucas1/JS-JJ/issues'
            },
        
            repository => {
                type => 'git',
                url  => 'git@github.com:lucas1/JS-JJ.git',
                web  => 'https://github.com/lucas1/JS-JJ'
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