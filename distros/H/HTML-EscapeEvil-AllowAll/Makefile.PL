use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'HTML::EscapeEvil::AllowAll',
    VERSION_FROM      => 'AllowAll.pm', # finds $VERSION
    PREREQ_PM         => {
							"HTML::EscapeEvil"	=> 0.04,
						}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'AllowAll.pm', # retrieve abstract from module
       AUTHOR         => 'Akira Horimoto <kurt0027@gmail.com>') : ()),
);
