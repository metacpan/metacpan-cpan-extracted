use Test::More tests => 4;

use HTML::FormFu::ExtJS;
use strict;
use warnings;

my $form = new HTML::FormFu::ExtJS;
$form->load_config_file("t/validation/inflate.yml");

$form->process({test => 1, date => '30.09.1985'});

is($form->submitted_and_valid, 1, "submitted and valid");
is(${$form->validation_response->{success}}, 1, "valid response");
is(exists $form->validation_response->{data}, 1, "data exists");
is_deeply($form->validation_response->{data}, {
          'test' => 1,
          'date' => '1985-09-30'
        }, 'date has been de- and inflated');