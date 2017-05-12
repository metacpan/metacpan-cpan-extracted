use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Digest::MD5::File',
    VERSION_FROM      => 'File.pm',
    PREREQ_PM         => {
        Digest::MD5    => 0,
        LWP::UserAgent => 0,
    },
    ($] >= 5.005 ? 
      (ABSTRACT_FROM  => 'File.pm',
       AUTHOR         => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>') : ()),
);
