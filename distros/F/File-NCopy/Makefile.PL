use 5.004;
use ExtUtils::MakeMaker;

print << 'EOT';

*** WARNING ***
Deprecated module. Use only if required by other module.
You can use File::Copy::Recursive instead.

*** REQUEST ***
Please use Test::Reporter to report test results - it's the only way to measure
popularity of distribution.

EOT

WriteMakefile(
    'NAME'	=> 'File::NCopy',
    'VERSION_FROM' => 'lib/File/NCopy.pm',
    'PREREQ_PM' => { 'File::Spec' => 0, 'Test::More'=>0},
    ($ExtUtils::MakeMaker::VERSION gt '6.30'? 
     ('LICENSE'		=> 'perl', ) : ()),
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => './lib/File/NCopy.pm', # retrieve abstract from module
       AUTHOR     => 'Alexandr Ciornii <alexchorny@'.'gmail.com>') : ()),
);
