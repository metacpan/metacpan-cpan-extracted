#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use MVC::Neaf::X::Session::SQL;

# Check prerequisites - don't want extra dependency
if (!eval { require DBD::SQLite }) {
    plan skip_all => "DBD::SQLite not found, skipping SQL/DBI session test";
    exit 0;
};

require DBI;
my $dbh = DBI->connect("dbi:SQLite:dbname=:memory:", '', '', { RaiseError => 1 } );

$dbh->do( <<"SQL" );
    CREATE TABLE my_sess (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id varchar(80) UNIQUE NOT NULL,
        user INT,
        unixt INT,
        raw varchar(4096)
    );
SQL

my %opt = ( dbh => $dbh, table => 'my_sess' );
my $engine = eval {
    MVC::Neaf::X::Session::SQL->new( %opt );
};
note "ERR (missing args): $@";
like $@, qr/id_as/, "no id field = no go";

$opt{id_as} = 'session_id';
$engine = eval {
    MVC::Neaf::X::Session::SQL->new( %opt );
};
note "ERR (missing args): $@";
like $@, qr/one of .* must/i, "no stored data = no go";

$engine = MVC::Neaf::X::Session::SQL->new(
    %opt, mapped_cols => [ 'user' ], content_as => 'raw', expire_as => 'unixt',
        session_ttl => 1000, session_renewal_ttl => 0 );

my $t0  = time;
my $ret = $engine->save_session( 'foobared', { user => 42, somedata => [5] } );
my $t1  = time;

note "save = ", explain $ret;
is $ret->{id}, 'foobared', "id round trip";

$dbh->do( "UPDATE my_sess SET user = 137" );

my $sth = $dbh->prepare( "SELECT * FROM my_sess" );
$sth->execute;
my $raw_data = $sth->fetchrow_hashref;

note "Real data in DB = ", explain $raw_data;

$ret = $engine->load_session( 'foobared' );
note "load = ", explain $ret;

# check auxiliary info
ok !$ret->{id}, "no id because re-sending to client NOT required";
my $exp = $ret->{expire};
ok defined $exp && $exp >= $t0 + 1000 && $exp <= $t1 + 1000,
    "expiration present and bound";

# check data
$ret = $ret->{data};
is $ret->{somedata}[0], 5, "deep data preserved";
is $ret->{user}, 137, "user updated just fine";


done_testing;
