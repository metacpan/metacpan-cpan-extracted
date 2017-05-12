use warnings;
use strict;
use Test::More;
use Mandel ();

plan skip_all => 'Set TEST_ONLINE to test' unless $ENV{TEST_ONLINE};
plan tests => 4;

my $db = "mandel_test_$0";
$db =~ s/\W/_/g;
my $connection = Mandel->connect("mongodb://localhost/$db");
my ($model, $collection, $iterator);

$model = $connection->model(person => {});
$collection = $connection->collection('person');

$collection->create({name => 'Bruce'})->save(
  sub {
    my ($iterator, $err) = @_;
    ok !$err, 'next: no error';
    Mojo::IOLoop->stop;
  }
);
Mojo::IOLoop->start;

$iterator = $collection->iterator;
$iterator->next(
  sub {
    my ($iterator, $err, $person) = @_;
    ok !$err, 'next: no error';
    isa_ok $iterator, 'Mandel::Iterator';
    isa_ok $person,   'Mandel::Document';
    Mojo::IOLoop->stop;
  }
);
Mojo::IOLoop->start;

$connection->storage->db->command(dropDatabase => 1) unless $ENV{KEEP_DATABASE};

