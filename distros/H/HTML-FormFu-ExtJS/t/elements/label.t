use Test::More tests => 3;

use HTML::FormFu::ExtJS;
use strict;
use warnings;

my $form = new HTML::FormFu::ExtJS;
$form->load_config_file("t/elements/label.yml");

is_deeply( $form->_render_items,
    [
      {
        'cls'   => 'x-form-item',
        'text'  => 'My First ExtJS Label',
        'name'  => 'labelname',
        'xtype' => 'label'
      }
    ]
);
is(scalar @{$form->_render_items}, 1);

ok($form->render_items);
