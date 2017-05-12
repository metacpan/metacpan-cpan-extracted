use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
if ($^O !~ /^mpe/i) {
  print STDERR
   "This module will only run under the MPE/iX operating system\n";
}
WriteMakefile(
    'NAME'              => 'MPE::File',
    'VERSION_FROM'      => 'File.pm', # finds $VERSION
    'PREREQ_PM'         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'File.pm', # retrieve abstract from module
       AUTHOR     => 'Ken Hirsch <kenhirsch@myself.com>') : ()),
    'LIBS'              => [''], # e.g., '-lm'
    'DEFINE'            => '', # e.g., '-DHAVE_SOMETHING'
    'INC'               => '', # e.g., '-I/usr/include/other'
    'PERL_MALLOC_OK'    => 1,
    'macro'             => {'MV'        => 'mv -f'},
);
