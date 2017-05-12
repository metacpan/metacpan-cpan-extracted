use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Image::Button',
    'VERSION_FROM'	=> 'lib/Image/Button.pm', # finds $VERSION
    'PREREQ_PM'		=> { 'GD' => 2.05 },
    'PMLIBDIRS'         => [ 'lib' ],
    'realclean'         => { FILES => "*~" },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT   => 'Create buttons for HTML forms using GD',
       AUTHOR     => 'Joan M. Garcia <jm@elfiral.net>') : ()),
);

