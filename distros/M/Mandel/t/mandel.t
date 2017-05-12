use Mojo::Base -strict;
use Test::More;
use lib 't/lib';
use MyModel;

{
  my $connection = MyModel->new;

  is_deeply $connection->namespaces, ['MyModel'], 'got namespaces';
  is_deeply [$connection->all_document_names], ['menu'], 'got document names';
  is $connection->class_for('menu'), 'MyModel::Menu', 'got class_for Menu';
}

{
  my $connection = MyModel->new(model_class => 'Dummy::Namespace')->connect;
  my $clone = $connection->connect;
  isnt $connection->storage,   $clone->storage,     'created clone, with fresh storage';
  is $connection->model_class, $clone->model_class, 'but with same model_class';
}

{
  my $connection = MyModel->new;

  @MyModel::Menu::INITIALIZE = ();
  $connection->initialize({any => 'thing'});
  is_deeply [@MyModel::Menu::INITIALIZE], ['MyModel::Menu', $connection, {any => 'thing'}], 'initialize with any thing';

  @MyModel::Menu::INITIALIZE = ();
  $connection->initialize(menu => {any => 'thing'});
  is_deeply [@MyModel::Menu::INITIALIZE], ['MyModel::Menu', $connection, {any => 'thing'}],
    'initialize with model name';

  @MyModel::Menu::INITIALIZE = ();
  $connection->initialize;
  is_deeply [@MyModel::Menu::INITIALIZE], ['MyModel::Menu', $connection, {}], 'initialize with defaults';

  is Mandel::Document->initialize, 'Mandel::Document', 'default initialize method';
}

{
  my $connection = MyModel->new;
  my $menu       = $connection->model('menu');

  is $menu->name,             'menu',               'menu name';
  is $menu->collection_name,  'menus',              'menu collection_name';
  is $menu->collection_class, 'Mandel::Collection', 'menu collection_class';
  is $menu->document_class,   'MyModel::Menu',      'menu document_class';
}

done_testing;
