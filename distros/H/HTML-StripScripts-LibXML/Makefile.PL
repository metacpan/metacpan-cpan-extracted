use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'HTML::StripScripts::LibXML',
    'VERSION_FROM'  => 'LibXML.pm',
    'ABSTRACT_FROM' => 'LibXML.pm',
    'AUTHOR'        => 'Clinton Gormley <clint@traveljury.com>',
    'PREREQ_PM'    => {
                        'Test::More'                 => 0,
                        'HTML::StripScripts::Parser' => 1.02,
                        'XML::LibXML'                => 1.58,
                      },
    $ExtUtils::MakeMaker::VERSION >= 6.31
    ? ( 'LICENSE' => 'perl' )
    : (),    
);

