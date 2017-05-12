use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'GD::Image::Orientation',
    VERSION_FROM      => 'Orientation.pm',
    PREREQ_PM         => {
       GD => 0,
    },
    ($] >= 5.005 ? 
      (ABSTRACT_FROM  => 'Orientation.pm',
       AUTHOR         => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>') : ()),
);
