use Mojo::Base -strict;
use Test::More;
use lib 't/lib';
use MyModel::Menu;

isa_ok 'MyModel::Menu', 'Mandel::Document';
isa_ok 'MyModel::Menu', 'Mojo::Base';

can_ok 'MyModel::Menu', 'field';
can_ok 'MyModel::Menu', 'soup';

my $obj = MyModel::Menu->new;

ok !$obj->is_changed, 'object has not been changed';
is $obj->soup('noodle'), $obj, 'setter returns instance';
is $obj->soup, 'noodle', 'getter returns value';
ok $obj->is_changed, 'object reports that it has been changed';

is(MyModel::Menu->model->collection_name, 'menus', 'import arg is collection name');

eval <<"DOCUMENT" or die $@;
package MyModel::Menu;
sub _build_data {
  +{ soup => 'cold' }
}
1;
DOCUMENT

is(MyModel::Menu->new->soup, 'cold', 'soup() value from _build_data');

done_testing;

