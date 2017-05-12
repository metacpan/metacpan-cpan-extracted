use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'IO::Socket::ByteCounter',
    VERSION_FROM      => 'lib/IO/Socket/ByteCounter.pm', 
    PREREQ_PM         => {
        'version' => 0,
    }, 
    ($] >= 5.005 ?   
      (ABSTRACT_FROM  => 'lib/IO/Socket/ByteCounter.pm',
       AUTHOR         => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>') : ()),
);
