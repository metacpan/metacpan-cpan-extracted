use ExtUtils::MakeMaker::CPANfile;

WriteMakefile(
    'NAME'              => 'Font::Fontconfig',
    'AUTHOR'            => 'Theo van Hoesel <tvanhoesel@perceptyx.com',
    'VERSION_FROM'      => 'lib/Font/Fontconfig.pm',
    'ABSTRACT_FROM'     => 'lib/Font/Fontconfig.pod',
    
    test => {
        'TESTS'         => 't/*.t t/*/*.t xt/*.t'
    }
);
