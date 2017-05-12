use Test::More tests => 4;

use HTML::FormFu::ExtJS;
use strict;
use warnings;

my $form = new HTML::FormFu::ExtJS;
$form->load_config_file("t/elements/blank.yml");


ok($form->render_items);
my $rendered = $form->render_items;
while($rendered =~ /Test html with <code>/g) {
	ok(1);
}