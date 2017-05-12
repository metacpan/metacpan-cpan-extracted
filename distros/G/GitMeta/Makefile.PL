######################################################################
# Makefile.PL for Git::Meta
# 2011, Mike Schilli <cpan@perlmeister.com>
######################################################################
use ExtUtils::MakeMaker;

my $meta_merge = {
    META_MERGE => {
        resources => {
            repository  => 'http://github.com/mschilli/gitmeta',
        },
    }
};

WriteMakefile(
    'NAME'           => 'GitMeta',
    'VERSION_FROM'   => 'lib/GitMeta.pm', # finds $VERSION
    'EXE_FILES'      => ["eg/gitmeta-update"],
    'PREREQ_PM'      => {
       Sysadm::Install => 0.37,
       Log::Log4perl   => 1.0,
       Pithub          => 0.01016,
       File::Temp      => 0.22,
       YAML            => 0.71,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/GitMeta.pm',
       AUTHOR     => 'Mike Schilli <cpan@perlmeister.com>') : ()),
    $ExtUtils::MakeMaker::VERSION >= 6.50 ? (%$meta_merge) : (),
);
