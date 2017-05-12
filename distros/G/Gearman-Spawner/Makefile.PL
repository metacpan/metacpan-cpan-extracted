use 5.010000;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME            => 'Gearman::Spawner',
    VERSION_FROM    => 'lib/Gearman/Spawner.pm',
    PREREQ_PM       => {
        'Carp'                      => 0,
        'Danga::Socket'             => 1.59,
        #'Gearman::Client'           => 1.11,
        #'Gearman::Client::Async'    => 0.94,
        #'AnyEvent::Gearman::Client' => 0.09,
        'Gearman::Server'           => 1.11,
        'IO::Socket::INET'          => 1.31,
        'POSIX'                     => 0,
        'Storable'                  => 0,
    },
    ABSTRACT_FROM   => 'lib/Gearman/Spawner.pm',
    AUTHOR          => 'Adam Thomason <athomason@cpan.org>',
);
