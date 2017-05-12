use Test::More tests => 1;

use HTML::FormFu::ExtJS;
use strict;
use warnings;

my $form = new HTML::FormFu::ExtJS;
$form->load_config_file('t/column_model/01-basic.yml');
my $data = $form->grid_data([{name => 'foo', sex => 0, cds => 3}, {name => 'bar', sex => 1, cds => 4}]);

is_deeply( $form->_column_model, [
          {
            'dataIndex' => 'name',
            'id' => 'name',
            'header' => 'name'
          },
          {
            'dataIndex' => 'created',
            'id' => 'created',
            'renderer' => \'Ext.util.Format.dateRenderer("d.m.Y")',
            'header' => 'Created',
            'dateFormat' => 'd.m.Y'
          },
          {
            'dataIndex' => 'sexValue',
            'hidden' => \1,
            'id' => 'sex-value',
            'header' => 'Sex'
          },
          {
            'dataIndex' => 'sex',
            'id' => 'sex',
            'header' => 'Sex'
          },
          {
            'dataIndex' => 'cds',
            'id' => 'cds',
            'header' => 'CDs'
          }
        ]);
