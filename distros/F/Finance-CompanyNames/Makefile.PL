use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'          => 'Finance::CompanyNames',
    'VERSION_FROM'	=> 'CompanyNames.pm',
    'PREREQ_PM'		=> {},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'CompanyNames.pm', # retrieve abstract from module
       AUTHOR        => 'GGHC Skunkworks <cpan@gghcwest.com>') : ()),
);
