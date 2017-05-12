use t::Online;
use Test::More;

my $connection = t::Online->mandel;
my $name       = int rand 10000;

$connection->storage->db->command(dropDatabase => 1);

{
  my $person = $connection->collection('person')->create({name => 'owner'});
  ok !$person->in_storage, 'person not in_storage';

  my $kittens = $person->kittens;
  is int(@$kittens), 0, 'no kittens yet';

  my $kitten = $person->push_kittens({name => $name + 2});
  ok $kitten->in_storage, 'kitten in_storage';
  ok $person->in_storage, 'person in_storage';

  $kitten = $person->push_kittens({name => $name + 0}, 0);
  $kitten = $person->push_kittens({name => $name + 1}, 1);
  is $kitten->name, $name + 1, 'push_kittens() return kitten';
  is int(@{$person->data->{kittens}}), 3, 'person has 3 kittens in list';

  $kittens = $person->kittens;
  is $kittens->[0]->name, $name, 'kittens.0 from cache';
  is $kittens->[1]->name, $name + 1, 'kittens.1 from cache';
  is $kittens->[2]->name, $name + 2, 'kittens.2 from cache';

  $kittens = $person->fresh->kittens;
  is $kittens->[2]->name, $name + 2, 'kittens from cache';
}

{
  my $kitten = $connection->collection('cat')->single;
  my $person = $connection->collection('person')->single;
  is int(@{$person->data->{kittens}}), 3, 'person has 3 kittens in list';

  my $kittens = $person->kittens;
  Mojo::IOLoop->start;
  is $person->remove_kittens($kitten), $person, 'remove_kittens() return self';
  Mojo::IOLoop->start;
  is int(@{$person->data->{kittens}}), 2, 'person has 2 kittens in list';

  $kittens = $person->kittens;
  is int(@$kittens), 2, 'only two left in cache';
}

{
  my $person  = $connection->collection('person')->single;
  my $kittens = $person->search_kittens({}, {limit => 10});
  my $all     = $kittens->all;
  isa_ok $kittens, 'Mandel::Collection';
  is_deeply $kittens->{query}, {'_id' => {'$in' => [map { $_->id } @$all]}}, 'got correct cat query';
  is_deeply $kittens->{extra}, {limit => 10}, 'got correct cat extra';

  is $kittens->count, 2, 'counted three kittens';
}

$connection->storage->db->command(dropDatabase => 1) unless $ENV{KEEP_DATABASE};

done_testing;
