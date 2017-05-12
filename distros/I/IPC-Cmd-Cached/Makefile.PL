######################################################################
# Makefile.PL for IPC::Cmd::Cached
# 2007, Mike Schilli <cpan@perlmeister.com>
######################################################################
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'IPC::Cmd::Cached',
    'VERSION_FROM' => 'Cached.pm', # finds $VERSION
    'PREREQ_PM'    => {
      Cache::FileCache => undef,
      IPC::Cmd         => 0.24,
      Storable         => 1,
      Log::Log4perl    => 1,
      Getopt::Std      => 0,
      Pod::Usage       => 1.14,
      File::Temp       => 0,
      Storable         => 0,
    }, # e.g., Module::Name => 1.1
    'EXE_FILES'         => [ qw(eg/run-cached eg/run-cached-all) ],
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Cached.pm',
       AUTHOR     => 'Mike Schilli <cpan@perlmeister.com>') : ()),
);
