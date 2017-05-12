use Kelp::Base -strict;
use Test::More;

use lib 't/lib';
use MyApp;

my $app = MyApp->new();

my $r1 = $app->rdb;
my $r2 = $app->rdb(type => 'other');
my $sql_create = 'CREATE TABLE authors (name varchar(12))';

$r1->do_transaction( sub { $r1->dbh->do($sql_create) } );
$r2->do_transaction( sub { $r2->dbh->do($sql_create) } );

# Switch type to other
{
    my $a1 = $app->rdbo('Author')->new( name => 'George Orwell' )->save;
    ok $a1->rowid;

    my $a2 = $app->rdbo('Author', type => 'other')->new( name => 'Umberto Eco' )->save;
    ok $a2->rowid;

    is $app->rdbo('Author::Manager')->get_authors_count, 1;
    is $app->rdbo('Author::Manager', type => 'other')->get_authors_count, 1;
}

# Switches back to default type
{
    my $a1 = $app->rdbo('Author')->new( name => 'Al Gore' )->save;
    ok $a1->rowid;

    is $app->rdbo('Author::Manager')->get_authors_count, 2;
    is $app->rdbo('Author::Manager', type => 'other')->get_authors_count, 1;
}

done_testing;
