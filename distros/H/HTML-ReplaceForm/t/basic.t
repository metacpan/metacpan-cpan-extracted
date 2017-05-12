
use Test::More 'no_plan';

use_ok('HTML::ReplaceForm','replace_form');

is(
    replace_form(\'<input name="foo">', {  foo => 'zoo' }),
    '<strong>zoo</strong>',
    'basic area for type text',
);

is(
    replace_form(\'<select name="foo"><option>MyOpt</option></select>', {  foo => 'zoo' }),
    '<strong>zoo</strong>',
    'basic area for type <select>',
);

is(
    replace_form(\'<textarea name="foo">My Content</textarea>', {  foo => 'zoo' }),
    '<strong>zoo</strong>',
    'basic area for type <textarea>',
);


is(
    replace_form(\'<input type="checkbox" name="foo" value="zoo">', {  foo => 'zoo' }),
    '[<strong>X</strong>]',
    'basic area for type checkbox, selected',
);

is(
    replace_form(\'<input type="checkbox" name="foo" value="DIFFERENT">', {  foo => 'zoo' }),
    '[ ] ',
    'basic area for type checkbox, unselected',
);

is(
    replace_form(\'<input type="radio" name="foo" value="zoo">', {  foo => 'zoo' }),
    '(<strong>X</strong>)',
    'basic area for type radio, selected',
);

is(
    replace_form(\'<input type="radio" name="foo" value="DIFFERENT">', {  foo => 'zoo' }),
    '( ) ',
    'basic area for type radio, unselected',
);



is(
    replace_form(\'<select name="foo"><option>MyOpt</option></select> After', {  foo => 'zoo' }),
    '<strong>zoo</strong> After',
    "<select> - Don't gobble text after the tag.",
);

is(
    replace_form(\'<textarea name="foo">My Content</textarea> After', {  foo => 'zoo' }),
    '<strong>zoo</strong> After',
    "<textarea> - Don't Gobble text after the tag. ",
);

