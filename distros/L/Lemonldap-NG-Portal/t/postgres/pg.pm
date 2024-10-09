use strict;
use Cwd;

use constant DBIPARAMS => {
    dbiChain    => 'dbi:Pg:dbname=llng;host=localhost;port=54432',
    dbiUser     => 'llng',
    dbiPassword => 'llng',
};
use constant CONTNAME => 'llng-pg-test';

sub startPg {
    my $initFile = getcwd . '/t/postgres/init.sql';
    system(
        'docker', 'run', '-d', '--name', CONTNAME, '--rm', '-e',
        'POSTGRES_PASSWORD=password', '-v',
        "$initFile:/docker-entrypoint-initdb.d/init.sql", "-p", "54432:5432",
        "postgres:15-bookworm"
    );
    sleep 3;
}

sub stopPg {
    system( 'docker', 'stop', CONTNAME );
}

1;
