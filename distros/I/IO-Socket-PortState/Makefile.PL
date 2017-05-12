use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'IO::Socket::PortState',
    VERSION_FROM      => 'PortState.pm',
    PREREQ_PM         => { IO::Socket::INET => 0, },
    ($] >= 5.005 ?    
      (ABSTRACT_FROM  => 'PortState.pm',
       AUTHOR         => 'Daniel Muey L<http://drmuey.com/cpan_contact.pl>') : ()),
);
