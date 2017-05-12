use Test::More tests => 3;

use HTML::FormFu::ExtJS;
use strict;
use warnings;

my $form = new HTML::FormFu::ExtJS;
$form->load_config_file("t/elements/fieldset.yml");

is_deeply( $form->_render_items,
    [
      {
        'nestedName' => 'outer',
        'title' => 'Fieldset Label',
        'xtype' => 'fieldset',
        'autoHeight' => 1,
        'items' => [
           {
             'hideLabel' => \0,
             'name' => 'outer.test2',
             'fieldLabel' => 'Test',
             'xtype' => 'textfield'
           }
         ]
      }
    ]
);

is(scalar @{$form->_render_items}, 1);

ok($form->render_items);
