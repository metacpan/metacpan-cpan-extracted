use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'GD::Image::AnimatedGif',
    VERSION_FROM      => 'AnimatedGif.pm', 
    PREREQ_PM         => {
        GD => 0
    },
    ($] >= 5.005 ? 
      (ABSTRACT_FROM  => 'AnimatedGif.pm',
       AUTHOR         => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>') : ()),
);
