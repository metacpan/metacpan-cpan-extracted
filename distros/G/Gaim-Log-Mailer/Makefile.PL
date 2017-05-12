######################################################################
# Makefile.PL for Gaim::Log::Mailer
# 2007, Mike Schilli <cpan@perlmeister.com>
######################################################################
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'Gaim::Log::Mailer',
    'VERSION_FROM' => 'Mailer.pm', # finds $VERSION
    'PREREQ_PM'    => {
      Gaim::Log::Parser => 0.10,
      Gaim::Log::Finder => 0,
      Log::Log4perl     => 1.0,
      URI::Find         => 0,
      Data::Throttler   => 0,
      Mail::DWIM        => 0,
      Text::TermExtract => 0,
      URI::URL          => 0,
      URI               => 0,
      Pod::Usage        => 0,
      YAML              => 0,
      File::Temp        => 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Mailer.pm',
       AUTHOR     => 'Mike Schilli <cpan@perlmeister.com>') : ()),
);
