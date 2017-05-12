use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'LCS::XS',
    'VERSION_FROM'	=> 'XS.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'XS.pm', # retrieve abstract from module
       AUTHOR     => 'Helmut Wollmersdorfer <helmut.wollmersdorfer@gmail.com>') : ()),
    'LICENSE' => 'perl_5',
    'MIN_PERL_VERSION' => '5.8.8',
    'LIBS'		=> [''], # e.g., '-lm'
    'DEFINE'		=> '', # e.g., '-DHAVE_SOMETHING'
    'INC'		=> '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    'OBJECT'		=> '$(O_FILES)', # link all the C files too
    'TEST_REQUIRES'		=> {
            "LCS" => "0",
            "Test::Deep" => "0",
            "Test::More" => "0.88",
    },
);
