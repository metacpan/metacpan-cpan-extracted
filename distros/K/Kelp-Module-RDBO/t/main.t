use Kelp::Base -strict;
use Test::More;

# For Dist::Zilla
use DBD::SQLite;
use File::Temp;

use lib 't/lib';
use MyApp;

my $app = MyApp->new();

ok $app->can('rdb');
ok $app->can('rdbo');

# Modules are not loaded yet
for ( qw/Author Book/ ) {
    ok(!Class::Inspector->loaded("MyApp::DB::$_"));
}

my $dbh = $app->rdb->dbh;
$app->rdb->do_transaction(sub{
    $dbh->do('CREATE TABLE authors ( name varchar(255) )');
    $dbh->do('CREATE TABLE books ( title varchar(255), author_id int not null )');
})
or do {
    fail "Failed creating tables";
    die;
};

my $author = $app->rdbo('Author')->new( name => 'George Orwell' )->save;
ok $author->rowid;

my $book = $app->rdbo('Book')->new(
    title     => '1984',
    author_id => $author->rowid
)->save;
ok $book->rowid;

my $book2 = $app->rdbo('Book')->new(
    title     => 'Animal Farm',
    author_id => $author->rowid
)->save;
ok $book2->rowid;

is $app->rdbo('Author::Manager')->get_authors_count, 1;
is $app->rdbo('Book::Manager')->get_books_count, 2;

done_testing;
