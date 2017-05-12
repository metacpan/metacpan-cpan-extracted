use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Mac::SysProfile',
    VERSION_FROM      => 'SysProfile.pm',
    PREREQ_PM         => {
        'Mac::PropertyList' => 0,
        'Scalar::Util' => 0,
    },
    ($] >= 5.005 ?   
      (ABSTRACT_FROM  => 'SysProfile.pm', 
       AUTHOR         => 'Daniel Muey L<http://drmuey.com/cpan_contact.pl>') : ()),
);
