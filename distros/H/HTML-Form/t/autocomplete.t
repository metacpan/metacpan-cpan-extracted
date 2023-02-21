#!perl

use strict;
use warnings;

use HTML::Form;
use Test::More;

my $form = HTML::Form->parse( <<'EOT', "http://localhost/" );
<form action="abc" name="foo">
  <input id="login-field"    name="username">
  <input id="password-field" name="password" autocomplete="password">
</form>
EOT

isa_ok( $form, 'HTML::Form' );

{
    my $input = $form->find_input('#password-field');
    is( $input->autocomplete, 'password', 'autocomplete parsed' );
    $input->autocomplete('foo');
    is( $input->autocomplete, 'foo', 'autocomplete is settable' );
}

{
    my $input = $form->find_input('#login-field');
    is( $input->autocomplete, undef, 'autocomplete is undef' );
    $input->autocomplete('foo');
    is( $input->autocomplete, 'foo', 'autocomplete is settable' );
}

done_testing();
