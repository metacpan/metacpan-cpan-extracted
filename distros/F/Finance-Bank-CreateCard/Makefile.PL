use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'              => 'Finance::Bank::CreateCard',
    'VERSION_FROM'      => 'CreateCard.pm', # finds $VERSION
    'PREREQ_PM'         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'CreateCard.pm', # retrieve abstract from module
       AUTHOR     => 'Robert J. McKay <robert@mckay.com>') : ()),
);

