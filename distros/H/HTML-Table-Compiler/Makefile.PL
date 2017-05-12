use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		    => 'HTML::Table::Compiler',
    'VERSION_FROM'	=> 'Compiler.pm', # finds $VERSION
    'PREREQ_PM'		=> {'HTML::Table' => undef}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Compiler.pm', # retrieve abstract from module
       AUTHOR     => 'Sherzod B. Ruzmetov <sherzodr@cpan.org>') : ())
);
