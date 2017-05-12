use t::Online;
use Test::More;

my $connection = t::Online->mandel;
my $name       = int rand 10000;

$connection->storage->db->command(dropDatabase => 1);

{
  my ($n, $err, $dino, $cat, $new_cat);

  $dino = $connection->collection('dinosaur')->create({});
  ok !$dino->in_storage, 'dino not in_storage';
  ok !$dino->{cache}{cat}, 'no cat in cache';

  $dino->cat({name => $name}, sub { (undef, $err, $cat) = @_; Mojo::IOLoop->stop; $n++; });
  Mojo::IOLoop->start;
  ok !$err, 'no error';
  ok $cat->in_storage,  'cat in_storage';
  ok $dino->in_storage, 'dino in_storage';
  ok $dino->{cache}{cat}, 'cat in cache';

  $cat = undef;
  $dino->cat(sub { (undef, $err, $cat) = @_; $n++; });
  ok $cat, 'cat from cache';

  $name++;
  $dino->cat({name => $name}, sub { (undef, $err, $new_cat) = @_; Mojo::IOLoop->stop; $n++; });
  Mojo::IOLoop->start;
  isnt $dino->cat->id, $cat->id, 'new cat is not old cat';
  is $new_cat->id, $new_cat->id, 'dino cat is updated';

  $cat = undef;
  $dino->fresh->cat(sub { (undef, $err, $cat) = @_; Mojo::IOLoop->stop; $n++; });
  Mojo::IOLoop->start;
  ok $cat, 'fresh cat';

  is $n, 4, 'four callbacks';
}

{
  is $connection->collection('dinosaur')->count, 1, 'one dinosaur';
  is $connection->collection('cat')->count,      1, 'the old cat was deleted';
}

$connection->storage->db->command(dropDatabase => 1) unless $ENV{KEEP_DATABASE};

done_testing;
