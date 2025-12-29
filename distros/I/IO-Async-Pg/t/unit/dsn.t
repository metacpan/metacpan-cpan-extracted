use strict;
use warnings;
use Test2::V0;

use IO::Async::Pg::Util qw(parse_dsn safe_dsn);

subtest 'parse basic DSN' => sub {
    my $parsed = parse_dsn('postgresql://localhost/testdb');
    is $parsed->{dbi_dsn}, 'dbi:Pg:dbname=testdb;host=localhost;port=5432', 'dbi_dsn';
    is $parsed->{user}, undef, 'no user';
    is $parsed->{password}, undef, 'no password';
};

subtest 'parse DSN with user and password' => sub {
    my $parsed = parse_dsn('postgresql://myuser:mypass@localhost/testdb');
    is $parsed->{dbi_dsn}, 'dbi:Pg:dbname=testdb;host=localhost;port=5432', 'dbi_dsn';
    is $parsed->{user}, 'myuser', 'user';
    is $parsed->{password}, 'mypass', 'password';
};

subtest 'parse DSN with port' => sub {
    my $parsed = parse_dsn('postgresql://localhost:5433/testdb');
    is $parsed->{dbi_dsn}, 'dbi:Pg:dbname=testdb;host=localhost;port=5433', 'custom port';
};

subtest 'parse DSN with options' => sub {
    my $parsed = parse_dsn('postgresql://localhost/testdb?sslmode=require');
    like $parsed->{dbi_dsn}, qr/sslmode=require/, 'sslmode in DSN';
};

subtest 'parse postgres:// alias' => sub {
    my $parsed = parse_dsn('postgres://localhost/testdb');
    is $parsed->{dbi_dsn}, 'dbi:Pg:dbname=testdb;host=localhost;port=5432', 'postgres:// works';
};

subtest 'parse full DSN' => sub {
    my $parsed = parse_dsn('postgresql://admin:secret@db.example.com:5432/production?sslmode=verify-full');
    is $parsed->{dbi_dsn}, 'dbi:Pg:dbname=production;host=db.example.com;port=5432;sslmode=verify-full', 'full DSN';
    is $parsed->{user}, 'admin', 'user';
    is $parsed->{password}, 'secret', 'password';
};

subtest 'safe_dsn masks password' => sub {
    my $safe = safe_dsn('postgresql://user:secretpass@localhost/db');
    is $safe, 'postgresql://user:***@localhost/db', 'password masked';
};

subtest 'safe_dsn with no password' => sub {
    my $safe = safe_dsn('postgresql://user@localhost/db');
    is $safe, 'postgresql://user@localhost/db', 'no change when no password';
};

subtest 'invalid DSN throws' => sub {
    my $died = dies { parse_dsn('not-a-valid-dsn') };
    like $died, qr/Cannot parse DSN/, 'invalid DSN throws';
};

done_testing;
