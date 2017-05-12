use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'HTML::GoogleMaps',
    VERSION_FROM      => 'lib/HTML/GoogleMaps.pm',
    PREREQ_PM         => {
      'Geo::Coder::Google' => .02,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/HTML/GoogleMaps.pm',
       AUTHOR         => 'Nathan Mueller <nate@cs.wisc.edu>') : ()),
);
