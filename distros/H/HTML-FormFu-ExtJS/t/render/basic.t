use Test::More tests => 2;

use HTML::FormFu::ExtJS;
use strict;
use warnings;

my $form = new HTML::FormFu::ExtJS;
$form->load_config_file("t/elements/text.yml");

is_deeply( $form->_render, {
	action => '',
	standardSubmit => 1,
          'buttons' => [],
		  'method' => 'post',
		  'baseParams' => {'x-requested-by' => 'ExtJS'},
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
        });
        
ok($form->render);
