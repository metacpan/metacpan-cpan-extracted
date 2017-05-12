use Test::More tests => 2;

use HTML::FormFu::ExtJS;
use strict;
use warnings;

my $form = new HTML::FormFu::ExtJS;
$form->load_config_file("t/elements/text.yml");
like($form->render( renderTo => 'main'), qr/renderTo/);
like($form->render({renderTo => 'main'}), qr/renderTo/);
