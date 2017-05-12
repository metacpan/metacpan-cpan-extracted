#!perl -wT
# $Id$
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test tests => 47;

    use_ok('Handel::Storage::RDBO');
    use_ok('Handel::Schema::RDBO::DB');
};


## make sure the settings stick
{
    my $connection = [
        'dbi:SQLite:dbname=F:\CPAN\handel.db'
    ];

    my $storage = Handel::Storage::RDBO->new({
        schema_class    => 'Handel::Schema::RDBO::Cart',
        connection_info => $connection
    });
    isa_ok($storage, 'Handel::Storage::RDBO');
    is_deeply($storage->connection_info, $connection, 'connection information was set');

    $storage->connection_info(undef);
    is($storage->connection_info, undef, 'connection info was unset');
};


## server@host style dsn
{
    my $db = Handel::Schema::RDBO::DB->get_db('dbi:mysql:mydatabase@myserver', 'myuser', 'mypass');
    is($db->database, 'mydatabase', 'database is set');
    is($db->host, 'myserver', 'server is set');
    is($db->username, 'myuser', 'user is set');
    is($db->password, 'mypass', 'password is set');
    is($db->port, undef, 'port is not set');
    is($db->driver, 'mysql', 'driver is set');
    is($db->dsn, 'dbi:mysql:database=mydatabase;host=myserver', 'dsn is set');
};


## server@host:port style dsn
{
    my $db = Handel::Schema::RDBO::DB->get_db('dbi:mysql:mydatabase@myserver:8080', 'myuser', 'mypass');
    is($db->database, 'mydatabase', 'database is set');
    is($db->host, 'myserver', 'server is set');
    is($db->username, 'myuser', 'user is set');
    is($db->password, 'mypass', 'password is set');
    is($db->port, 8080, 'port is set');
    is($db->driver, 'mysql', 'driver is set');
    is($db->dsn, 'dbi:mysql:database=mydatabase;host=myserver;port=8080', 'dsn is set');
};


## :database style dsn
{
    my $db = Handel::Schema::RDBO::DB->get_db('dbi:Pg:mydatabase', 'myuser', 'mypass');
    is($db->database, 'mydatabase', 'database is set');
    is($db->host, undef, 'server is not set');
    is($db->username, 'myuser', 'user is set');
    is($db->password, 'mypass', 'password is set');
    is($db->port, undef, 'port is not set');
    is($db->driver, 'pg', 'driver is set');
    is($db->dsn, 'dbi:Pg:dbname=mydatabase', 'dsn is set');
};


## :dbname=;host=;port= style dsn
{
    my $db = Handel::Schema::RDBO::DB->get_db('dbi:mysql:dbname=mydatabase;host=localhost;port=4133', 'myuser', 'mypass');
    is($db->database, 'mydatabase', 'database is set');
    is($db->host, 'localhost', 'server is set');
    is($db->username, 'myuser', 'user is set');
    is($db->password, 'mypass', 'password is set');
    is($db->port, 4133, 'port is set');
    is($db->driver, 'mysql', 'driver is set');
    is($db->dsn, 'dbi:mysql:database=mydatabase;host=localhost;port=4133', 'dsn is set');
};


## :dbname=;host=;port= style dsn
{
    my $db = Handel::Schema::RDBO::DB->get_db('dbi:mysql:db=mydatabase;server=localhost;port=4133', 'myuser', 'mypass');
    is($db->database, 'mydatabase', 'database is set');
    is($db->host, 'localhost', 'server is set');
    is($db->username, 'myuser', 'user is set');
    is($db->password, 'mypass', 'password is set');
    is($db->port, 4133, 'port is set');
    is($db->driver, 'mysql', 'driver is set');
    is($db->dsn, 'dbi:mysql:database=mydatabase;host=localhost;port=4133', 'dsn is set');
};


## :dbname=;host=;port= style dsn
{
    my $db = Handel::Schema::RDBO::DB->get_db('dbi:mysql:database=mydatabase;hostname=localhost;port=4133', 'myuser', 'mypass');
    is($db->database, 'mydatabase', 'database is set');
    is($db->host, 'localhost', 'server is set');
    is($db->username, 'myuser', 'user is set');
    is($db->password, 'mypass', 'password is set');
    is($db->port, 4133, 'port is set');
    is($db->driver, 'mysql', 'driver is set');
    is($db->dsn, 'dbi:mysql:database=mydatabase;host=localhost;port=4133', 'dsn is set');
};
