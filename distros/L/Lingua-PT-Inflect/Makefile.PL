use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Lingua::PT::Inflect',
    'VERSION_FROM'	=> 'Inflect.pm', # finds $VERSION
    'PREREQ_PM'		=> {'Lingua::PT::Hyphenate' => 1.01},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (AUTHOR              => 'Jose Castro <cog@cpan.org>') : ()),
);
