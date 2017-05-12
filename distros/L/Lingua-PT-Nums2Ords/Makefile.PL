use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Lingua::PT::Nums2Ords',
    'VERSION_FROM'	=> 'Nums2Ords.pm', # finds $VERSION
    'PREREQ_PM'		=> {'Lingua::PT::Nums2Words' => 0.01}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (AUTHOR     => 'Jose Alves de Castro <cog@cpan.org>') : ()),
);
