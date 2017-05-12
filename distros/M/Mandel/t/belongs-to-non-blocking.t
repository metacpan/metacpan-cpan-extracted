use t::Online;
use Test::More;

my $connection = t::Online->mandel;
my $name       = int rand 10000;

$connection->storage->db->command(dropDatabase => 1);

{
  my $cat = $connection->collection('cat')->create({});
  my ($n, $err, $person);

  ok !$cat->in_storage, 'cat not in_storage';
  ok !$cat->{cache}{person}, 'no person in cache';
  $cat->person({name => $name}, sub { (undef, $err, $person) = @_; Mojo::IOLoop->stop; $n++; });
  Mojo::IOLoop->start;

  ok !$err, 'no error';
  ok $cat->{cache}{person}, 'person in cache';
  ok $person->in_storage, 'person in_storage';
  ok $cat->in_storage,    'cat in_storage';

  $person = undef;
  $cat->person(sub { (undef, $err, $person) = @_; $n++; });
  ok $person, 'person from cache';

  is $n, 2, 'two callbacks';
}

{
  my ($n, $err, $cat, $person, $new_person);

  $connection->collection('person')->single(sub { (undef, $err, $person) = @_; Mojo::IOLoop->stop; $n++; });
  Mojo::IOLoop->start;
  ok $person->in_storage, 'found person';

  $person->search_cats->single(sub { (undef, $err, $cat) = @_; Mojo::IOLoop->stop; $n++; });
  Mojo::IOLoop->start;
  ok $cat->in_storage, 'found cat';

  $name++;
  $cat->person({name => $name}, sub { (undef, $err, $new_person) = @_; Mojo::IOLoop->stop; $n++; });
  Mojo::IOLoop->start;
  isnt $new_person->id, $person->id, 'new person is not old person';

  $person = undef;
  $cat->person(sub { (undef, $err, $person) = @_; $n++ });
  ok $person, 'person from cache';
  is $new_person->id, $person->id, 'new person from cache';

  is $n, 4, 'four callbacks';
}

{
  my ($n, $err, $cat, $person);
  $connection->collection('person')->search({name => $name})
    ->single->search_cats->single(sub { (undef, $err, $cat) = @_; Mojo::IOLoop->stop; $n++; });
  Mojo::IOLoop->start;
  $cat->person(sub { (undef, $err, $person) = @_; Mojo::IOLoop->stop; $n++; });
  Mojo::IOLoop->start;

  $cat->person(sub { (undef, $err, $person) = @_; $n++; });
  ok $person, 'person from cache on fresh object';

  $cat->fresh->person(sub { (undef, $err, $person) = @_; Mojo::IOLoop->stop; $n++; });
  Mojo::IOLoop->start;
  ok $person, 'fresh person';

  is $n, 4, 'four callbacks';
}

{
  my ($err, $n);
  $connection->collection('person')->count(sub { (undef, $err, $n) = @_; Mojo::IOLoop->stop; });
  Mojo::IOLoop->start;
  is $n, 2, 'two persons in the database';
}

$connection->storage->db->command(dropDatabase => 1) unless $ENV{KEEP_DATABASE};

done_testing;
