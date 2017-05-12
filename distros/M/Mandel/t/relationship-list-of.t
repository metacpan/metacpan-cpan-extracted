use Mojo::Base -strict;
use Mandel ();
use Test::More;

my $connection = Mandel->new;
my $person     = $connection->model(person => {})->model('person');
my $kitten     = $connection->model(cat => {})->model('cat');

ok !$person->document_class->can('kittens'),        'person cannot kittens()';
ok !$person->document_class->can('push_kittens'),   'person cannot push_kittens()';
ok !$person->document_class->can('search_kittens'), 'person cannot search_kittens()';

isa_ok $person->relationship(list_of => kittens => $kitten->document_class)->monkey_patch,
  'Mandel::Relationship::ListOf';
ok $person->document_class->can('kittens'),        'person can kittens()';
ok $person->document_class->can('push_kittens'),   'person can push_kittens()';
ok $person->document_class->can('search_kittens'), 'person can search_kittens()';

if ($ENV{TEST_ONLINE}) {
  is_deeply $person->new_collection($connection)->create({})->kittens, [], 'empty kitten list by default';
}

done_testing;
