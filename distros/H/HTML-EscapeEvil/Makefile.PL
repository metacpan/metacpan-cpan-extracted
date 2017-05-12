use 5.008000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'HTML::EscapeEvil',
    VERSION_FROM      => 'EscapeEvil.pm', # finds $VERSION
    PREREQ_PM         => {
							'Class::Accessor' => 0.19,
							'HTML::Filter' => 2.10,
							'HTML::Element' => 3.16,
						}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'EscapeEvil.pm', # retrieve abstract from module
       AUTHOR         => 'Akira Horimoto <kurt0027@gmail.com>') : ()),
);
