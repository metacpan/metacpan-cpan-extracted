use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'IO::Socket::PortState::cPanel',
    VERSION_FROM      => 'cPanel.pm',
    PREREQ_PM         => { IO::Socket::PortState => 0 },
    ($] >= 5.005 ?    
      (ABSTRACT_FROM  => 'cPanel.pm',
       AUTHOR         => 'Daniel Muey L<http://drmuey.com/cpan_contact.pl>') : ()),
);
