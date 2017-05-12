use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'GD::Image::Thumbnail',
    VERSION_FROM      => 'Thumbnail.pm',
    PREREQ_PM         => {
        GD => 0,
    },
    ($] >= 5.005 ? 
      (ABSTRACT_FROM  => 'Thumbnail.pm',
       AUTHOR         => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>') : ()),
);
