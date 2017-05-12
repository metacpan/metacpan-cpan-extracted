use strict;
use warnings;

use Test::More tests => 2;

use HTML::FormFu;

my $form = HTML::FormFu->new(
    { tt_args => { INCLUDE_PATH => 'share/templates/tt/xhtml' } } );

$form->load_config_file('t/jquery_validation_errors_join.yml');

$form->process( {
        foo => '',
} );

is(
    $form->jquery_validation_errors_join('<br/>')->{foo},
    "One<br/>Two"
);

is(
    $form->jquery_validation_errors_join( '<li>', '</li>' )->{foo},
    "<li>One</li><li>Two</li>"
);
