######################################################################
# Makefile.PL for Mail::DWIM
# 2007, Mike Schilli <cpan@perlmeister.com>
######################################################################
use ExtUtils::MakeMaker;

my $meta_merge = {
    META_MERGE => {
        resources => {
            repository  => 'http://github.com/mschilli/mail-dwim-perl',
        },
    }
};

WriteMakefile(
    'NAME'         => 'Mail::DWIM',
    'VERSION_FROM' => 'DWIM.pm', # finds $VERSION
    'PREREQ_PM'    => {
      File::Temp    => 0,
      YAML          => 0,
      Mail::Mailer  => 0,
      Log::Log4perl => 1,
      Sys::Hostname => 1,
      Test::More    => 0,
    }, # e.g., Module::Name => 1.1
    $ExtUtils::MakeMaker::VERSION >= 6.50 ? (%$meta_merge) : (),
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'DWIM.pm',
       AUTHOR     => 'Mike Schilli <cpan@perlmeister.com>') : ()),
);
