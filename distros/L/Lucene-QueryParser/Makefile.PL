use 5.00503;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Lucene::QueryParser',
    'VERSION_FROM'	=> 'QueryParser.pm', # finds $VERSION
    'PREREQ_PM'		=> {
                Text::Balanced => 0
            }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (
       AUTHOR     => 'Simon Cozens <simon@kasei.com>') : ()),
);
