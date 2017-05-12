use t::Online;
use Test::More;

my $connection = t::Online->mandel;
my $name       = int rand 10000;

$connection->storage->db->command(dropDatabase => 1);

{
  my $person = $connection->collection('person')->create({});
  my $cats   = $person->cats;
  Mojo::IOLoop->start;
  ok !$person->in_storage, 'person not in_storage';
  is_deeply $cats, [], 'no cats in database';
}

{
  my $person = $connection->collection('person')->create({});
  my $cat = $person->add_cats({name => $name});
  Mojo::IOLoop->start;
  ok $person->in_storage, 'person in in_storage';

  my $cats = $person->cats;
  Mojo::IOLoop->start;
  is int @$cats, 1, 'cats in storage';

  $cats = $person->cats;
  is int @$cats, 1, 'cats from cache';
}

{
  my $person = $connection->collection('person')->create({})->save;
  my $cats   = $person->cats;
  Mojo::IOLoop->start;
  ok $person->in_storage, 'person in_storage';

  $cats = $person->cats;
  is int @$cats, 0, 'person without cats from cache';

  $name++;
  my $cat = $person->add_cats({name => $name});
  Mojo::IOLoop->start;
  $cats = $person->cats;
  is int @$cats, 1, 'person with one cat from cache';
  is $cats->[0]->id, $cat->id, 'cat in cache with expected id';

  $cats = $person->fresh->cats;
  Mojo::IOLoop->start;
  is int @$cats, 1, 'person with one fresh cat';
}

{
  my ($n, $err, $cat);
  my $person = $connection->collection('person')->search({})->single;
  my $cats = $person->search_cats({}, {limit => 10});
  isa_ok $cats, 'Mandel::Collection';
  is_deeply $cats->{query}, {'person.$id' => $person->id}, 'got correct cat query';
  is_deeply $cats->{extra}, {limit => 10}, 'got correct cat extra';

  is $cats->count, 1, 'counted one cat';
}

$connection->storage->db->command(dropDatabase => 1) unless $ENV{KEEP_DATABASE};

done_testing;
