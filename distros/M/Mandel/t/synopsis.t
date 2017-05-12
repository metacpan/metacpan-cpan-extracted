use Mojo::Base -strict;
use Test::More;

plan skip_all => 'Set TEST_ONLINE to test' unless $ENV{TEST_ONLINE};
plan tests => 13;

my $db = "mandel_test_$0";
$db =~ s/\W/_/g;

{

  package MyModel;
  use Mojo::Base 'Mandel';

  package MyModel::Cat;
  use Mandel::Document;
  field [qw( name type )];
  belongs_to person => 'MyModel::Person';

  package MyModel::Person;
  use Mandel::Document;
  field [qw( name age )];
  has_many cats        => 'MyModel::Cat';
  has_one favorite_cat => 'MyModel::Cat';

  package main;
}

my $connection = MyModel->connect("mongodb://localhost/$db");
my $persons    = $connection->collection('person');

$connection->storage->db->command(dropDatabase => 1);

{
  my $p1 = $persons->create({name => 'Bruce', age => 30});
  $p1->save(
    sub {
      my ($p1, $err) = @_;
      isa_ok $p1, 'MyModel::Person';
      ok !$err, 'save: no error' or diag $err;
      Mojo::IOLoop->stop;
    }
  );
  Mojo::IOLoop->start;
}

{
  $persons->count(
    sub {
      my ($persons, $err, $n_persons) = @_;
      isa_ok $persons, 'Mandel::Collection';
      is $n_persons, 1, 'count persons';
      Mojo::IOLoop->stop;
    }
  );
  Mojo::IOLoop->start;
}

{
  $persons->all(
    sub {
      my ($persons, $err, $objs) = @_;
      isa_ok $persons, 'Mandel::Collection';
      ok !$err, 'all: no error' or diag $err;
      is int @$objs, 1, 'got one person';
      for my $p (@$objs) {
        isa_ok $p, 'MyModel::Person';
        $p->age(25)->save(sub { });
      }
      Mojo::IOLoop->stop;
    }
  );
  Mojo::IOLoop->start;
}

{
  $persons->search({name => 'Bruce'})->single(
    sub {
      my ($persons, $err, $person) = @_;
      isa_ok $persons, 'Mandel::Collection';
      isa_ok $person,  'MyModel::Person';
      ok !$err, 'search: no error' or diag $err;

      $person->cats(
        sub {
          my ($person, $err, $cats) = @_;
          $_->remove(sub { }) for @$cats;
        }
      );

      $person->remove(
        sub {
          my ($person, $err) = @_;
          isa_ok $person, 'MyModel::Person';
          ok !$err, 'remove: no error' or diag $err;
          Mojo::IOLoop->stop;
        }
      );
    }
  );
  Mojo::IOLoop->start;
}

$connection->storage->db->command(dropDatabase => 1) unless $ENV{KEEP_DATABASE};

