use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'AUTHOR'            => 'Matt Sanford (mzsanford@cpan.org)',
    'NAME'		=> 'Image::OrgChart',
    'VERSION_FROM'	=> 'OrgChart.pm', # finds $VERSION
    'PREREQ_PM'		=> { GD => 1.16 },
);
