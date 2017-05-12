use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Lingua::Treebank::Const',
    'VERSION_FROM'	=> '../Treebank.pm', # finds $VERSION
    'PREREQ_PM'		=> {
			   },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Const.pm', # retrieve abstract from module
       AUTHOR     => 'Jeremy G Kahn <kahn@cpan.org>') : ()),
);
