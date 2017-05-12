use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Lingua::Treebank',
    'VERSION_FROM'	=> 'Treebank.pm', # finds $VERSION
    'PREREQ_PM'		=> {
			   },
    'EXE_FILES'    => [ qw(
		scripts/get-words
		scripts/list-edges
		scripts/list-rewrites
		scripts/tree-collapse
		scripts/tree-inflate
		scripts/vocabulary)],
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Treebank.pm', # retrieve abstract from module
       AUTHOR     => 'Jeremy Gillmor Kahn <kahn@cpan.org>') : ()),
);
