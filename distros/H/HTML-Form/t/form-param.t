#!perl

use strict;
use warnings;

use HTML::Form ();
use Test::More;

my $form
    = HTML::Form->parse( <<"EOT", base => "http://example.com", strict => 1 );
<form>
<input type="hidden" name="hidden_1">

<input type="checkbox" name="checkbox_1" value="c1_v1" CHECKED>
<input type="checkbox" name="checkbox_1" value="c1_v2" CHECKED>
<input type="checkbox" name="checkbox_2" value="c2_v1" CHECKED>

<select name="multi_select_field" multiple="1">
 <option> 1
 <option> 2
 <option> 3
</select>
</form>
EOT

is( $form->param, 4, '4 params' );
is(
    j( $form->param ), "hidden_1:checkbox_1:checkbox_2:multi_select_field",
    'param names'
);

is(
    $form->find_input('checkbox_1')->type, 'checkbox',
    'checkbox_1 is a checkbox'
);
is( $form->param('hidden_1'),   '',      'hidden1 empty' );
is( $form->param('checkbox_1'), 'c1_v1', 'checkbox_1' );
is(
    j( $form->param('checkbox_1') ), 'c1_v1:c1_v2',
    'all checkbox_1 values'
);
is( $form->param('checkbox_2'),      'c2_v1', 'checkbox_2 value' );
is( j( $form->param('checkbox_2') ), 'c2_v1', 'all checkbox_2 values' );
is(
    $form->find_input('checkbox_2')->type, 'checkbox',
    'checkbox_2 is a checkbox'
);

ok(
    !defined( $form->param('multi_select_field') ),
    'no multi-select field value'
);
is(
    j( $form->param('multi_select_field') ), '',
    'no multi_select_field values'
);
subtest 'unknown' => sub {
    ok( !defined( $form->param('unknown') ), 'single unknown param' );
    is( j( $form->param('unknown') ), '', 'multiple unknown params' );
};

subtest 'exceptions' => sub {
    eval { $form->param( 'hidden_1', 'x' ); };
    like( $@, qr/readonly/, 'error on setting readonly field' );
    is( j( $form->param('hidden_1') ), '', 'hidden_1 empty' );

    eval { $form->param( 'checkbox_1', 'foo' ); };
    like( $@, qr/Illegal value/, 'error on setting illegal value' );
    is(
        j( $form->param('checkbox_1') ), 'c1_v1:c1_v2',
        'checkbox_1 was not reset after illegal value'
    );
};

$form->param( 'checkbox_1', 'c1_v2' );
is(
    j( $form->param('checkbox_1') ), 'c1_v2',
    'checkbox_1 set to single value'
);

is( j( $form->param('checkbox_1') ), 'c1_v2', 'checkbox_1 value reset' );
$form->param( 'checkbox_1', [] );
is( j( $form->param('checkbox_1') ), '', 'checkbox_1 empty' );
$form->param( 'checkbox_1', [ 'c1_v2', 'c1_v1' ] );
is(
    j( $form->param('checkbox_1') ), 'c1_v1:c1_v2',
    'multiple checkbox_1 values have been set'
);

$form->param( 'checkbox_1', [] );
is( j( $form->param('checkbox_1') ), '', 'checkbox_1 empty again' );
$form->param( 'checkbox_1', 'c1_v2', 'c1_v1' );
is(
    j( $form->param('checkbox_1') ), 'c1_v1:c1_v2',
    'multiple checkbox_1 values again'
);

$form->param( 'multi_select_field', 3, 2 );
is(
    j( $form->param('multi_select_field') ), "2:3",
    'multiple multi_select_field values'
);

# This should be replaced.  We could just be comparing arrays.
sub j {
    join( ":", @_ );
}

done_testing();
