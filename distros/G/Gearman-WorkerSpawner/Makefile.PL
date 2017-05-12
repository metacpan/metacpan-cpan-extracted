use inc::Module::Install;

name            'Gearman-WorkerSpawner';
all_from        'lib/Gearman/WorkerSpawner.pm';

requires        'Carp'                          => 0;
requires        'Danga::Socket'                 => 1.59;
requires        'Gearman::Client'               => 1.09;
requires        'Gearman::Client::Async'        => 0.94;
requires        'Gearman::Server'               => 1.09;
requires        'Storable'                      => 0;

WriteAll;
