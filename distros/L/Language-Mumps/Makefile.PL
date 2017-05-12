use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Language::Mumps',
    'VERSION_FROM' => 'lib/Language/Mumps.pm', # finds $VERSION
    'LICENSE' => 'restricted',
    'EXE_FILES' => ['bin/pmumps'],
        ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Language/Mumps.pm', # retrieve abstract from module
       AUTHOR     => 'Steffen Mueller <smueller@cpan.org>') : ()),

);
