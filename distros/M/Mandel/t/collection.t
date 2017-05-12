use Mojo::Base -strict;
use Mandel::Collection;
use Mandel::Document;
use Mandel::Model;
use Test::More;

my $collection = Mandel::Collection->new;
my $model = Mandel::Model->new(document_class => 'Mandel::Document');
my $document;

{
  eval { $collection->connection };
  like $@, qr{connection required in constructor}, 'connection: required in constructor';

  eval { $collection->model };
  like $@, qr{model required in constructor}, 'model: required in constructor';

  eval { $collection->create };
  like $@, qr{model required in constructor}, 'create: model required in constructor';
}

{
  $collection->model($model);
  $document = $collection->create;
  isa_ok $document, 'Mandel::Document';
  is $document->{data}, undef, 'raw was not set in create()';
  is $document->in_storage, 0, 'in_storage = 0';
  is $document->model, $model, 'model = $model';
}

{
  $document = $collection->create({foo => 123});
  is_deeply $document->{data}, {foo => 123}, 'raw was set in create()';
  is_deeply $document->dirty,  {foo => 1},   'dirty was set from doc';
  is $document->in_storage, 0, 'in_storage = 0';
}

done_testing;
