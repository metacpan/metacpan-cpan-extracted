use strict;
use warnings;
use Test::More;

use HealthCheck::Diagnostic::DBHPing;
use DBI;
use DBD::SQLite;

my $nl = $] >= 5.016 ? ".\n" : "\n";

eval { HealthCheck::Diagnostic::DBHPing->check };
is $@, sprintf( "Valid 'dbh' is required at %s line %d$nl",
    __FILE__, __LINE__ - 2 );

eval { HealthCheck::Diagnostic::DBHPing->new->check };
is $@, sprintf( "Valid 'dbh' is required at %s line %d$nl",
    __FILE__, __LINE__ - 2 );

eval { HealthCheck::Diagnostic::DBHPing->new( dbh => {} )->check };
is $@, sprintf( "Valid 'dbh' is required at %s line %d$nl",
    __FILE__, __LINE__ - 2 );

eval { HealthCheck::Diagnostic::DBHPing->check( dbh => bless {} ) };
is $@, sprintf( "Valid 'dbh' is required at %s line %d$nl",
    __FILE__, __LINE__ - 2 );

eval { HealthCheck::Diagnostic::DBHPing->check( dbh => sub {} ) };
is $@, sprintf( "Valid 'dbh' is required at %s line %d$nl",
    __FILE__, __LINE__ - 2 );


my $dbname = 'dbname=:memory:';
my $dbh = DBI->connect("dbi:SQLite:$dbname","","");

is_deeply( HealthCheck::Diagnostic::DBHPing->new( dbh => $dbh )->check, {
    label  => 'dbh_ping',
    status => 'OK',
    info   => "Successful SQLite ping of $dbname",
}, "OK status as expected" );

$dbh->disconnect;
is_deeply( HealthCheck::Diagnostic::DBHPing->check( dbh => $dbh ), {
    status => 'CRITICAL',
    info   => "Unsuccessful SQLite ping of dbname=:memory:",
}, "CRITICAL status as expected" );

# Now try it with a username and a coderef
$dbh = sub { DBI->connect("dbi:SQLite:$dbname","FakeUser","") };

is_deeply( HealthCheck::Diagnostic::DBHPing->new( dbh => $dbh )->check, {
    label  => 'dbh_ping',
    status => 'OK',
    info   => "Successful SQLite ping of $dbname as FakeUser",
}, "OK status as expected" );

# Turn it into a coderef that returns a disconnected dbh
$dbh = do { my $x = $dbh; sub { my $y = $x->(); $y->disconnect; $y } };

is_deeply( HealthCheck::Diagnostic::DBHPing->check( dbh => $dbh ), {
    status => 'CRITICAL',
    info   => "Unsuccessful SQLite ping of $dbname as FakeUser",
}, "CRITICAL status as expected" );

done_testing;

