use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Geo::Coder::Cloudmade',
    'VERSION_FROM'	=> 'Cloudmade.pm', # finds $VERSION
    PREREQ_PM           => { },
);
