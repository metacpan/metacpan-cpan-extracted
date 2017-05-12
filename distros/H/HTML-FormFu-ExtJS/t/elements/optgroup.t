use Test::More tests => 5;

use HTML::FormFu::ExtJS;
use strict;
use warnings;

my $form = new HTML::FormFu::ExtJS;
$form->load_config_file("t/elements/optgroup.yml");

my $rendered = $form->_render_items;

is($rendered->[0]->{name}, "foo");

ok( $form->render_items, "dumping");

ok($form->render_items =~ /group 1/);

ok($form->render_items =~ /item 1a/);

TODO: {
	local $TODO = "Highlight and disable group items";
	ok($form->render_items =~ /disabled/);
}
