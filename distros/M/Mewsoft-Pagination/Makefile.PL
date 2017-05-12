use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Mewsoft::Pagination',
    VERSION_FROM      => 'lib/Mewsoft/Pagination.pm',
    PREREQ_PM         => {},
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/Mewsoft/Pagination.pm',
       AUTHOR         => 'Ahmed Amin Elsheshtawy <support@mewsoft.com>') : ()),
);
