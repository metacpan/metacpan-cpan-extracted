use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'HTML::WWWTheme',
    'VERSION_FROM' => 'WWWTheme.pm', # finds $VERSION
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
    ('ABSTRACT_FROM' => 'WWWTheme.pm',
    'AUTHOR' => 'Chad Hogan <chogan@uvastro.phys.uvic.ca>') : ()),
);
