use t::Online;
use Test::More;

my $connection = t::Online->mandel;
my $name       = int rand 10000;

$connection->storage->db->command(dropDatabase => 1);

{
  my $dino = $connection->collection('dinosaur')->create({});
  ok !$dino->in_storage, 'dino not in_storage';
  ok !$dino->{cache}{cat}, 'no cat in cache';

  my $cat = $dino->cat({name => $name});
  ok $cat->in_storage,  'cat in_storage';
  ok $dino->in_storage, 'dino in_storage';
  ok $dino->{cache}{cat}, 'cat in cache';

  $cat = $dino->cat;
  ok $cat, 'cat from cache';

  $name++;
  my $new_cat = $dino->cat({name => $name});
  Mojo::IOLoop->start;
  isnt $dino->cat->id, $cat->id, 'new cat is not old cat';
  is $new_cat->id, $new_cat->id, 'dino cat is updated';

  $cat = $dino->fresh->cat;
  ok $cat, 'fresh cat';
}

{
  is $connection->collection('dinosaur')->count, 1, 'one dinosaur';
  is $connection->collection('cat')->count,      1, 'the old cat was deleted';
}

$connection->storage->db->command(dropDatabase => 1) unless $ENV{KEEP_DATABASE};

done_testing;
