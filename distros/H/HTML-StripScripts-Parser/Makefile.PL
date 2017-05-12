use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'         => 'HTML::StripScripts::Parser',
    'VERSION_FROM' => 'Parser.pm',
    'ABSTRACT_FROM' => 'Parser.pm',
    'AUTHOR'        => 'Nick Cleaton <nick@cleaton.net>,'
        . ' Clinton Gormley <clint@traveljury.com>',
    'PREREQ_PM'    => {
                        'Test::More'         => 0,
                        'HTML::StripScripts' => 1.05,
                        'HTML::Parser'       => 3.56,
                      },
    $ExtUtils::MakeMaker::VERSION >= 6.31
    ? ( 'LICENSE' => 'perl' )
    : (),    
);

