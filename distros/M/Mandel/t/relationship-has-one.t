use Mojo::Base -strict;
use Mandel ();
use Test::More;

my $connection = Mandel->new;

{
  my $person = $connection->model(person => {})->model('person');
  my $cat    = $connection->model(cat    => {})->model('cat');

  ok !$person->document_class->can('cat'), 'person cannot cat()';

  isa_ok $person->relationship(has_one => cat => $cat->document_class)->monkey_patch, 'Mandel::Relationship::HasOne';
  ok $person->document_class->can('cat'), 'person can cat()';
}

{
  my $p = $connection->collection('person')->create({name => 'Bruce', age => 30});
  my @args;

  no warnings 'redefine';
  local *Mandel::Collection::remove = sub { $_[1]->($_[0], 'ooops!'); $_[0]; };
  local *Mandel::Collection::save = sub { die "Should never come to this!" };

  $p->cat({}, sub { @args = @_; Mojo::IOLoop->stop; });
  Mojo::IOLoop->start;
  is $args[1], 'ooops!', 'failed on remove()';
}

done_testing;
