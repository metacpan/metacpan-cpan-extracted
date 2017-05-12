use Test::More tests => 3;

use HTML::FormFu::ExtJS;
use strict;
use warnings;

my $form = new HTML::FormFu::ExtJS;
$form->load_config_file("t/elements/datetime.yml");

like($form->render_items, qr/"value":"\d+-\d+-\d+"/);

is(scalar @{$form->_render_items}, 2);

ok($form->render_items);
