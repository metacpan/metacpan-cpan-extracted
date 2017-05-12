use t::Online;
use Test::More;

my $connection = t::Online->mandel;
my $name       = int rand 10000;

$connection->storage->db->command(dropDatabase => 1);

{
  my ($n, $err, $kitten, $kittens);
  my $person = $connection->collection('person')->create({name => 'owner'});
  ok !$person->in_storage, 'person not in_storage';

  $person->kittens(sub { (undef, $err, $kittens) = @_; Mojo::IOLoop->stop; $n++; });
  Mojo::IOLoop->start;
  is int(@$kittens), 0, 'no kittens yet';

  $person->push_kittens({name => $name + 2}, sub { (undef, $err, $kitten) = @_; Mojo::IOLoop->stop; $n++; });
  Mojo::IOLoop->start;
  ok !$err, 'no error after push' or diag $err;
  ok $kitten->in_storage, 'kitten in_storage';
  ok $person->in_storage, 'person in_storage';

  $person->push_kittens({name => $name + 0}, 0, sub { (undef, $err, $kitten) = @_; Mojo::IOLoop->stop; ++$n });
  Mojo::IOLoop->start;
  $person->push_kittens({name => $name + 1}, 1, sub { (undef, $err, $kitten) = @_; Mojo::IOLoop->stop; ++$n });
  Mojo::IOLoop->start;
  is int(@{$person->data->{kittens}}), 3, 'person has 3 kittens in list';
  ok !$err, 'no error after 0,1' or diag $err;

  $kittens = [];
  $person->kittens(sub { (undef, $err, $kittens) = @_; $n++; });
  is $kittens->[0]->name, $name, 'kittens.0 from cache';
  is $kittens->[1]->name, $name + 1, 'kittens.1 from cache';
  is $kittens->[2]->name, $name + 2, 'kittens.2 from cache';

  $kittens = [];
  $person->fresh->kittens(sub { (undef, $err, $kittens) = @_; Mojo::IOLoop->stop; $n++; });
  Mojo::IOLoop->start;
  is $kittens->[2]->name, $name + 2, 'kittens from cache';

  is $n, 6, 'six callbacks';
}

{
  my ($n, $err, $kittens);
  my $kitten = $connection->collection('cat')->single;

  my $person = $connection->collection('person')->single;
  is int(@{$person->data->{kittens}}), 3, 'person has 3 kittens in list';

  $err = 'should_not_be_set';
  $person->kittens(sub { (undef, $err, $kittens) = @_; Mojo::IOLoop->stop; $n++; });
  Mojo::IOLoop->start;
  $person->remove_kittens($kitten, sub { (undef, $err) = @_; Mojo::IOLoop->stop; $n++; });
  Mojo::IOLoop->start;
  ok !$err, 'no error' or diag $err;
  is int(@{$person->data->{kittens}}), 2, 'person has 2 kittens in list';

  $kittens = [];
  $person->kittens(sub { (undef, $err, $kittens) = @_; $n++; });
  is int(@$kittens), 2, 'only two left in cache';

  is $n, 3, 'three callbacks';
}

$connection->storage->db->command(dropDatabase => 1) unless $ENV{KEEP_DATABASE};

done_testing;
