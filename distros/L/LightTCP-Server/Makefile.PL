use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'LightTCP::Server',
    VERSION_FROM      => 'lib/LightTCP/Server.pm',
    ABSTRACT_FROM     => 'lib/LightTCP/Server.pm',
    AUTHOR            => 'Hans Harder',
    LICENSE           => 'perl',
    PL_FILES          => {},
    MIN_PERL_VERSION  => '5.008',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'IO::Socket::INET'=> 0,
        'IPC::Open3'      => 0,
        'threads'         => 0,
        'threads::shared' => 0,
        'File::Temp'      => 0,
    },
    TEST_REQUIRES => {
        'Test::More' => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/HansH111/LightTCP-Server.pm.git',
                web  => 'https://github.com/HansH111/LightTCP-Server.pm',
            },
            bugtracker => {
                web => 'https://github.com/HansH111/LightTCP-Server.pm/issues',
            },
        },
    },
);

package MY;

sub libscan {
    my ($self, $file) = @_;
    return '' if $file =~ /\.(log|tmp|bak|old)$/;
    return $file;
}
