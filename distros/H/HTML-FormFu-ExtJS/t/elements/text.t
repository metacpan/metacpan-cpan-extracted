use Test::More tests => 3;

use HTML::FormFu::ExtJS;
use strict;
use warnings;

my $form = new HTML::FormFu::ExtJS;
$form->load_config_file("t/elements/text.yml");
is_deeply( $form->_render_items,
	[ { hideLabel => \1, "fieldLabel" => undef, "name" => "test", labelWidth => 10, id => "test_id", "xtype" => "textfield" },
	{ hideLabel => \0, "fieldLabel" => "Test", "name" => "test2", "xtype" => "textfield" } ] );
is(scalar @{$form->_render_items}, 2);

ok($form->render_items);
