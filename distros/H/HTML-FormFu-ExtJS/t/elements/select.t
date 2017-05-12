use Test::More tests => 7;

use HTML::FormFu::ExtJS;
use strict;
use warnings;

my $form = new HTML::FormFu::ExtJS;
$form->load_config_file("t/elements/select.yml");

$form->process;

my $rendered = $form->_render_items;

is($rendered->[0]->{emptyText}, undef);
is($rendered->[1]->{emptyText}, "test");
is($rendered->[1]->{something}, "else");

is(${$rendered->[3]->{store}}, "customStore", "store attribute is unquoted");

is($rendered->[4]->{value}, "Wird geladen", "wird geladen");

use Data::Dumper; print Dumper $rendered->[4];

ok( $form->render_items, "dumping");

like( $form->render, qr/["",""]/);
