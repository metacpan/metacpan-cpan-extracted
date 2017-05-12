use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
if ($^O !~ /^mpe/i) {
  print STDERR "This module will only run under the MPE/iX operating system\n";
}
WriteMakefile(
    'NAME'              => 'MPE::Spoonfeed',
    'VERSION_FROM'      => 'Spoonfeed.pm', # finds $VERSION
    'PREREQ_PM'         => { MPE::CIvar => 1.01,
                             MPE::Process => 0.01, 
                             MPE::File => 0.04 },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Spoonfeed.pm', # retrieve abstract from module
       AUTHOR     => 'Ken Hirsch <kenhirsch@myself.com>') : ()),
    'LIBS'              => [''], # e.g., '-lm'
    'DEFINE'            => '', # e.g., '-DHAVE_SOMETHING'
    'INC'               => '', # e.g., '-I/usr/include/other'
    'PERL_MALLOC_OK'    => 1,
    'macro'             => {'MV'        => 'mv -f'},
);
