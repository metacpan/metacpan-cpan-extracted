use t::Online;
use Test::More;

my $connection = t::Online->mandel;
my $name       = int rand 10000;

$connection->storage->db->command(dropDatabase => 1);

{
  my $person = $connection->collection('person')->create({});
  my $cat = $connection->collection('cat')->create({});
  $person->add_cats($cat);
  Mojo::IOLoop->start;
  ok $person->in_storage, 'person in in_storage';

  my $cats = $person->cats;
  Mojo::IOLoop->start;
  is int @$cats, 1, 'cats in storage';

  $cats = $person->cats;
  is int @$cats, 1, 'cats from cache';
}

{
  my $person = $connection->collection('person')->create({});
  my $cat = $connection->collection('cat')->create({})->save;
  $person->add_cats($cat);
  Mojo::IOLoop->start;
  ok $person->in_storage, 'person in in_storage';

  my $cats = $person->cats;
  Mojo::IOLoop->start;
  is int @$cats, 1, 'cats in storage';

  $cats = $person->cats;
  is int @$cats, 1, 'cats from cache';
}

{
  my $person = $connection->collection('person')->create({});
  my $cat = $connection->collection('cat')->create({})->save;
  $cat->person($person);
  Mojo::IOLoop->start;
  ok $person->in_storage, 'person in in_storage';

  my $cats = $person->cats;
  Mojo::IOLoop->start;
  is int @$cats, 1, 'cats in storage';

  $cats = $person->cats;
  is int @$cats, 1, 'cats from cache';
}

$connection->storage->db->command(dropDatabase => 1) unless $ENV{KEEP_DATABASE};

done_testing;

