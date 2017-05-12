use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Math::Fibonacci::Phi',
    VERSION_FROM      => 'Phi.pm',
    PREREQ_PM         => {
       'Math::Fibonacci' => 0
    },
    ($] >= 5.005 ? 
      (ABSTRACT_FROM  => 'Phi.pm',
       AUTHOR         => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>') : ()),
);
