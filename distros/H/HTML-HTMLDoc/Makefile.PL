use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'HTML::HTMLDoc',
    'VERSION_FROM'	=> 'lib/HTML/HTMLDoc.pm', # finds $VERSION
    'PREREQ_PM'		=> {IPC::Open3}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/HTML/HTMLDoc.pm', # retrieve abstract from module
       AUTHOR     => 'Michael Frankl <mfrankl@seibert-media.net>') : ()),
);
