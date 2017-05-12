
use HTML::FormBuilder::Select;
use Test::More tests => 24;
use strict;

my $basicselect = HTML::FormBuilder::Select->new(
    id      => 'basic',
    name    => 'Basic',
    options => [{
            value => '1',
            text  => 'One'
        }
    ],
    values => [1],
);

## Basic Tests
is $basicselect->id,   'basic', 'ID accessor returns id';
is $basicselect->name, 'Basic', 'name accessor returns name';
is_deeply $basicselect->options,
    [{
        value => '1',
        text  => 'One'
    }
    ],
    'Options returns correct structure';
is_deeply $basicselect->values, [1], 'values accessor returns correct list';

my $widget_html = $basicselect->widget_html;
like $widget_html, qr/value="1" SELECTED/, 'widget_select shows correct value';
like $widget_html, qr/ id="basic"/,        'html shows correct id';
like $widget_html, qr/ name="Basic"/,      'html shows correct name';
like $widget_html, qr/One/,                'Option displayed';

my $hidden_html = $basicselect->hidden_html;
like $hidden_html, qr/value="1"/,     'value set in hidden';
like $hidden_html, qr/ id="basic"/,   'html shows correct id in hidden';
like $hidden_html, qr/ name="Basic"/, 'html shows correct name in name';

## Resetting options
$basicselect->options([{
            value => 'foo',
            text  => 'Foo'
        },
        {
            value => 'bar',
            text  => 'Bar'
        }]);
my $hidden_html = $basicselect->hidden_html;
like $hidden_html, qr/value="1"/,     'value set in hidden';
like $hidden_html, qr/ id="basic"/,   'html shows correct id in hidden';
like $hidden_html, qr/ name="Basic"/, 'html shows correct name in name';

my $widget_html = $basicselect->widget_html;
unlike $widget_html, qr/value="1" SELECTED/, 'widget_select shows correct value';
like $widget_html,   qr/ id="basic"/,        'html shows correct id';
like $widget_html,   qr/ name="Basic"/,      'html shows correct name';
like $widget_html,   qr/Foo/,                'Option displayed';

## Resetting values

$basicselect->values(['qwerty']);
my $hidden_html = $basicselect->hidden_html;
like $hidden_html, qr/value="qwerty"/, 'value set in hidden';
like $hidden_html, qr/ id="basic"/,    'html shows correct id in hidden';
like $hidden_html, qr/ name="Basic"/,  'html shows correct name in name';

my $widget_html = $basicselect->widget_html;
unlike $widget_html, qr/value="1" SELECTED/, 'widget_select shows correct value';
like $widget_html,   qr/ id="basic"/,        'html shows correct id';
like $widget_html,   qr/ name="Basic"/,      'html shows correct name';

