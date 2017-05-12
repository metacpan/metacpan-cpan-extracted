use t::Online;
use Test::More;

my $connection = t::Online->mandel;
my $name       = int rand 10000;

$connection->storage->db->command(dropDatabase => 1);

{
  my $cat = $connection->collection('cat')->create({});
  my $person;

  ok !$cat->in_storage, 'cat not in_storage';
  ok !$cat->{cache}{person}, 'no person in cache';
  $person = $cat->person({name => $name});

  ok $cat->{cache}{person}, 'person in cache';
  ok $person->in_storage, 'person in_storage';
  ok $cat->in_storage,    'cat in_storage';

  $person = $cat->person;
  ok $person, 'person from cache';
}

{
  my ($cat, $person, $new_person);

  $person = $connection->collection('person')->single;
  ok $person->in_storage, 'found person';

  $cat = $person->search_cats->single;
  ok $cat->in_storage, 'found cat';

  $name++;
  $new_person = $cat->person({name => $name});
  isnt $new_person->id, $person->id, 'new person is not old person';

  $person = $cat->person;
  ok $person, 'person from cache';
  is $new_person->id, $person->id, 'new person from cache';
}

{
  my $cat = $connection->collection('person')->search({name => $name})->single->search_cats->single;
  my $person = $cat->person;
  Mojo::IOLoop->start;

  $person = $cat->person;
  ok $person, 'person from cache on fresh object';

  $cat->fresh;
  ok $cat->{fresh}, 'fresh is set';
  $person = $cat->fresh->person;
  Mojo::IOLoop->start;
  ok $person, 'fresh person';
  ok !$cat->{fresh}, 'fresh is reset';
}

{
  my $n = $connection->collection('person')->count;
  is $n, 2, 'two persons in the database';
}

$connection->storage->db->command(dropDatabase => 1) unless $ENV{KEEP_DATABASE};

done_testing;
