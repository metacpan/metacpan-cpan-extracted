use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Filter::Indent::HereDoc',
    'VERSION_FROM'	=> 'HereDoc.pm', # finds $VERSION
    'PREREQ_PM'		=> { Filter::Simple => 0 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (AUTHOR     => 'Jon Allen <jj@jonallen.info>') : ()),
);
