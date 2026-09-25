use strict;
use warnings;

use Test::More tests => 12;

use HTML::FormFu;

# RT#106557 - fields without a name must not emit
# "Use of uninitialized value $root in hash element" (or any other
# 'uninitialized' warning) during process() or render()

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, @_ };

my $form = HTML::FormFu->new(
    { tt_args => { INCLUDE_PATH => 'share/templates/tt/xhtml' } } );

$form->populate(
    {   elements => [
            { type => 'Text', name => 'foo' },

            # a Button's force_default(1) used to hit the nested-hash
            # code with an undefined name
            { type => 'Submit',        value   => 'Go' },
            { type => 'Button',        value   => 'Push' },
            { type => 'ContentButton', content => 'Click' },
            { type => 'Text' },
            { type => 'Textarea' },
            { type => 'Select',        options => [ [ 1, 'one' ] ] },
            { type => 'Radiogroup',    options => [ [ 1, 'one' ] ] },
            { type => 'Checkboxgroup', options => [ [ 1, 'one' ] ] },
            { type => 'Date' },
        ],
    } );

$form->process( { foo => 'bar' } );

ok( $form->submitted_and_valid, 'submitted_and_valid' );

is( $form->param_value('foo'), 'bar', 'named field value' );

is_deeply( [ keys %{ $form->params } ], ['foo'], 'only named field in params' );

my $string_html = $form->render;

like(
    $string_html,
    qr{<input type="submit" value="Go" />},
    'unnamed submit renders without name attribute'
);

like( $string_html, qr{<select>},
    'unnamed select renders without name attribute' );

like(
    $string_html,
    qr{<textarea cols="40" rows="20">},
    'unnamed textarea renders without name attribute'
);

like(
    $string_html,
    qr{<button type="button">Click</button>},
    'unnamed content button renders without name attribute'
);

like(
    $string_html,
    qr{<input type="radio" value="1" />},
    'unnamed radiogroup renders without name attribute'
);

like(
    $string_html,
    qr{<input type="checkbox" value="1" />},
    'unnamed checkboxgroup renders without name attribute'
);

$form->render_method('tt');

$form->render;

# setting the name to undef should also be silent

$form->get_field('foo')->name(undef);

is( $form->get_field( { type => 'Text' } )->name, undef, 'name(undef)' );

$form->process( { foo => 'bar' } );

is_deeply( $form->params, {}, 'no params once every field is unnamed' );

is_deeply( \@warnings, [], 'no warnings' )
    or diag( join '', @warnings );
