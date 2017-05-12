use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

print <<"EOF";

*** WARNING ***

The interface for this module has changed between versions 0.03 and 0.04
(and may yet change in the future -- it's still alpha and in a bit of a
state of flux).

If you have been using earlier versions of thie module, please read the
section on "DIFFERENCES FROM THE LAST VERSION" in the README file.
I will now pause for five seconds to let you read this notice.

EOF

sleep 5;

WriteMakefile(
    'NAME'		=> 'Lingua::SoundChange',
    'VERSION_FROM'	=> 'SoundChange.pm', # finds $VERSION
    'PREREQ_PM'		=> { Test::More => 0.19, }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'SoundChange.pm', # retrieve abstract from module
       AUTHOR     => 'Philip Newton <pne@cpan.org>') : ()),
);
