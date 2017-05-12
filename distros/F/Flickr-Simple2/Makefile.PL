use 5.008000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Flickr::Simple2',
    VERSION_FROM      => 'lib/Flickr/Simple2.pm', # finds $VERSION
    PREREQ_PM         => {
                            'Carp' => 0,
                            'Digest::MD5' => 0,
                            'Exception::Class::TCF' => 0.03,
                            'Iterator::Simple' => 0.05,
                            'LWP::Simple' => 5.8,
                            'URI' => 1.3,
                            'XML::Simple' => 2.18 },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Flickr/Simple2.pm', # retrieve abstract from module
       AUTHOR         => 'Jason L. Froebe <jason@froebe.net>') : ()),
);
