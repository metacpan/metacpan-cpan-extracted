use Test::More tests => 5;

use HTML::FormFu::ExtJS;
use strict;
use warnings;

my $form = new HTML::FormFu::ExtJS;
$form->load_config_file("t/elements/text.yml");

$form->process({test => 1});

isnt($form->submitted_and_valid, 1);
is(${$form->validation_response->{success}}, 0, "not valid");

$form->process({test2 => 1});

is($form->submitted_and_valid, 1);
is(${$form->validation_response->{success}}, 1, "valid");

is($form->validation_response->{data}->{test2}, 1, "data avaiable");