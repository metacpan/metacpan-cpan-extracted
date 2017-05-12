use Mojo::Base -strict;
use Mandel ();
use Test::More;

create_packages();

my $connection = Mandel->new;
my $person     = $connection->model(person => {})->model('person');
my $cat        = $connection->model(cat => {})->model('cat');

{
  diag 'The class names might change';
  is $person->document_class, 'Mandel::Document::__ANON_1__::Person', 'person document_class';
  is $cat->document_class,    'Mandel::Document::__ANON_2__::Cat',    'cat document_class';
}

{
  isa_ok $person->document_class,   'Mandel::Document';
  isa_ok $person->collection_class, 'Mandel::Collection';

  $cat->collection_class('Custom::Collection');
  is $cat->collection_class, 'Custom::Collection', 'set collection_class';
  isa_ok $cat->collection_class, 'Mandel::Collection';

  is $cat->collection_name, 'cats', 'collection generated from name';
}

done_testing;

sub create_packages {
  eval <<'  PACKAGE' or die $@;
  package Custom::Collection;
  use Mojo::Base 'Mandel::Collection';
  1;
  PACKAGE
}
