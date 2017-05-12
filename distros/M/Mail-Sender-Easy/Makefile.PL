use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Mail::Sender::Easy',
    VERSION_FROM      => 'Easy.pm', 
    PREREQ_PM         => {
                          'File::Spec'   => 0,
                          'Mail::Sender' => 0,
                          'version'      => 0, 
    },
    ($] >= 5.005 ?    
      (ABSTRACT_FROM  => 'Easy.pm', 
       AUTHOR         => 'Daniel Muey, L<http://drmuey.com/cpan_contact.pl>') : ()),
);
