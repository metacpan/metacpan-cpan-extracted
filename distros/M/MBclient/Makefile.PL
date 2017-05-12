use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'MBclient',
    VERSION_FROM      => 'lib/MBclient.pm', # finds $VERSION
    LICENSE           => 'MIT',
    MIN_PERL_VERSION  => '5.006_001',
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/sourceperl/MBclient.git',
                web  => 'https://github.com/sourceperl/MBclient',
            },
        },
    },
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/MBclient.pm', # retrieve abstract from module
       AUTHOR         => 'Lefebvre Loic <lle@cpan.org>') : ()),
);
