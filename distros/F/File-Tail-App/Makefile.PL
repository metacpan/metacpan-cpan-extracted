use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'File::Tail::App',
    VERSION_FROM      => 'App.pm', 
    PREREQ_PM         => {
        'File::Tail' => 0,
    }, 
    ($] >= 5.005 ?     
      (ABSTRACT_FROM  => 'App.pm', 
       AUTHOR         => 'Daniel Muey, <http://drmuey.com/cpan_contact.pl>') : ()),
);
