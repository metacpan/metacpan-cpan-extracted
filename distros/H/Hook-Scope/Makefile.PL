use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Hook::Scope',
    'VERSION_FROM'	=> 'Scope.pm', # finds $VERSION
    'PREREQ_PM'		=> {
			   'B::Generate' => '1.06',
			    'optimizer'  => '0.05',
			   }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Scope.pm', # retrieve abstract from module
       AUTHOR     => 'Arthur Bergman <abergman@cpan.org>') : ()),
    'LIBS'		=> [''], # e.g., '-lm'
    'DEFINE'		=> '', # e.g., '-DHAVE_SOMETHING'
    'INC'		=> '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # 'OBJECT'		=> '$(O_FILES)', # link all the C files too
);
