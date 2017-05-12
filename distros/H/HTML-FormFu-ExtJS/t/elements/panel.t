use Test::More tests => 3;

use HTML::FormFu::ExtJS;
use strict;
use warnings;

my $form = new HTML::FormFu::ExtJS;
$form->load_config_file("t/elements/panel.yml");

my $expected = [
  {
    'layout' => 'hfit',
    'containsScrollbar' => 'true',
    'title' => 'Company',
    'autoScroll' => 'true',
    'xtype' => 'panel',
    'items' => [
               {
                 'hideLabel' => \1,
                 'name' => 'test',
                 'fieldLabel' => undef,
                 'id' => 'test_id',
                 'xtype' => 'textfield',
                 'labelWidth' => '10'
               },
               {
                 'hideLabel' => \0,
                 'name' => 'test2',
                 'fieldLabel' => 'Test',
                 'xtype' => 'textfield'
               }
             ]
  }
];

is_deeply( $form->_render_items,$expected);

is(scalar @{$form->_render_items}, 1);

ok($form->render_items);
