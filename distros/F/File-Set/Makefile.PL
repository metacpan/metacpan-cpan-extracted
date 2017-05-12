use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'File::Set',
    'VERSION_FROM'	=> 'Set.pm', # finds $VERSION
    'PREREQ_PM'		=> {
      'Cwd' => 0.01,
      'Digest::MD5' => 0.01,
      'File::Temp' => 0.01
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Set.pm', # retrieve abstract from module
       AUTHOR     => 'Rob Mueller <cpan@robm.fastmail.fm>') : ()),
);
