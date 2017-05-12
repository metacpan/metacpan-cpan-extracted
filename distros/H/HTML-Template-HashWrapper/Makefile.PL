use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'HTML::Template::HashWrapper',
    'VERSION_FROM'	=> 'lib/HTML/Template/HashWrapper.pm', # finds $VERSION
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      ('ABSTRACT_FROM'	=> 'lib/HTML/Template/HashWrapper.pm',
       AUTHOR     => 'Greg Fast <gdf@speakeasy.net>') : ()),
);
