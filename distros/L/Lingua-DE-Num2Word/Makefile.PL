use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'              => 'Lingua::DE::Num2Word',
    'VERSION_FROM'      => 'Num2Word.pm',
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (AUTHOR     => 'Richard Jelinek <rj@petamem.com>, Roman Vasicek <rv@petamem.com>') : ())
);
