use Mojo::Base -strict;
use Mandel ();
use Test::More;

my $connection = Mandel->new;
my $person     = $connection->model(person => {})->model('person');
my $cat        = $connection->model(cat => {})->model('cat');

ok !$person->document_class->can('cats'),        'person cannot cats()';
ok !$person->document_class->can('add_cat'),     'person cannot add_cat()';
ok !$person->document_class->can('search_cats'), 'person cannot search_cats()';

isa_ok $person->relationship(has_many => cats => $cat->document_class)->monkey_patch, 'Mandel::Relationship::HasMany';
ok $person->document_class->can('cats'),        'person can cats()';
ok $person->document_class->can('add_cats'),    'person can add_cat()';
ok $person->document_class->can('search_cats'), 'person can search_cats()';

done_testing;
