use ExtUtils::MakeMaker;
 
WriteMakefile(
    NAME             => 'IP::Decimal',
    ABSTRACT         => 'Convert IP to Decimal and Decimal to IP',
    AUTHOR           => 'Lucas Tiago de Moraes <lucastiagodemoraes@gmail.com>',
    VERSION_FROM     => 'lib/IP/Decimal.pm',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.010001',
     
    META_MERGE => {
        'meta-spec' => {
          version => 2,
        },
      
        resources => {
            homepage => 'https://github.com/lucas1/IP-Decimal',
        
            bugtracker => {
                web => 'https://github.com/lucas1/IP-Decimal/issues'
            },
        
            repository => {
                type => 'git',
                url  => 'git@github.com:lucas1/IP-Decimal.git',
                web  => 'https://github.com/lucas1/IP-Decimal'
            }
        }        
    },
     
    PREREQ_PM => {
        'Exporter' => 0,
        'Data::Validate::IP' => 0,
        'NetAddr::IP::Util' => 0,
        'Math::Int128' => 0
    },
     
    test => {
        TESTS => 't/*.t'
    }    
);