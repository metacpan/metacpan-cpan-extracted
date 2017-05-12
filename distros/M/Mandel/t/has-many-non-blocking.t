use t::Online;
use Test::More;

my $connection = t::Online->mandel;
my $name       = int rand 10000;

$connection->storage->db->command(dropDatabase => 1);

{
  my ($err, $cats);
  my $person = $connection->collection('person')->create({});
  $person->cats(sub { (undef, $err, $cats) = @_; Mojo::IOLoop->stop; });
  Mojo::IOLoop->start;
  ok !$person->in_storage, 'person not in_storage';
  is_deeply $cats, [], 'no cats in database';
}

{
  my ($n, $err, $cat, $cats);
  my $person = $connection->collection('person')->create({});
  $person->add_cats({name => $name}, sub { (undef, $err, $cat) = @_; Mojo::IOLoop->stop; $n++; });
  Mojo::IOLoop->start;
  ok $person->in_storage, 'person in in_storage';

  $person->cats(sub { (undef, $err, $cats) = @_; Mojo::IOLoop->stop; $n++; });
  Mojo::IOLoop->start;
  is int @$cats, 1, 'cats in storage';

  $cats = [];
  $person->cats(sub { (undef, $err, $cats) = @_; $n++; });
  is int @$cats, 1, 'cats from cache';

  is $n, 3, 'three callbacks';
}

{
  my ($n, $err, $cat, $cats);
  my $person = $connection->collection('person')->create({});
  $person->save(sub { Mojo::IOLoop->stop if ++$n == 2; });
  $person->cats(sub { (undef, $err, $cats) = @_; Mojo::IOLoop->stop if ++$n == 2; });
  Mojo::IOLoop->start;
  ok $person->in_storage, 'person in_storage';

  $person->cats(sub { (undef, $err, $cats) = @_; $n++; });
  is int @$cats, 0, 'person without cats from cache';

  $name++;
  $person->add_cats({name => $name}, sub { (undef, $err, $cat) = @_; Mojo::IOLoop->stop; $n++; });
  Mojo::IOLoop->start;
  $person->cats(sub { (undef, $err, $cats) = @_; $n++; });
  is int @$cats, 1, 'person with one cat from cache';
  is $cats->[0]->id, $cat->id, 'cat in cache with expected id';

  $cats = [];
  $person->fresh->cats(sub { (undef, $err, $cats) = @_; Mojo::IOLoop->stop; $n++; });
  Mojo::IOLoop->start;
  is int @$cats, 1, 'person with one fresh cat';

  is $n, 6, 'six callbacks';
}

$connection->storage->db->command(dropDatabase => 1) unless $ENV{KEEP_DATABASE};

done_testing;
