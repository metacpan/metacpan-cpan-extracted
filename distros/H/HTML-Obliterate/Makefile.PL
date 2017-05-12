use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'HTML::Obliterate',
    VERSION_FROM      => 'lib/HTML/Obliterate.pm',
    PREREQ_PM         => {
        'version' => 0,
    }, 
    ($] >= 5.005 ?     
      (ABSTRACT_FROM  => 'lib/HTML/Obliterate.pm',
       AUTHOR         => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>') : ()),
);
