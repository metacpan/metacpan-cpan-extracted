use strict;
use warnings;
use Test::More;
use HTML::Blitz ();

my $prefix = '<div id=irrelevant>1 2 3</div> <div class="x y">';
my $suffix = '</div> <div class=x title="eng glo oxy"> &amp; </div>';

sub wrapped {
    $prefix . $_[0] . $suffix
}

sub run {
    my ($selector, $html) = @_;
    my $blitz = HTML::Blitz->new([$selector => [replace_inner_text => 'xyzzy']]);
    $blitz->apply_to_html('(test)', wrapped $html)->process
}

is run('*', '<p title=a>b</p>'), '<div id=irrelevant>xyzzy</div> <div class="x y">xyzzy</div> <div class=x title="eng glo oxy">xyzzy</div>',
    'universal selector';

is run('p', '<p title=a>b</p>'), wrapped('<p title=a>xyzzy</p>'),
    'type selector';

is run('[title]', '<p title>b</p>'), '<div id=irrelevant>1 2 3</div> <div class="x y"><p title>xyzzy</p></div> <div class=x title="eng glo oxy">xyzzy</div>',
    'attribute presence selector';

is run('[\\t\\i\\t\\le]', '<p title>b</p>'), '<div id=irrelevant>1 2 3</div> <div class="x y"><p title>xyzzy</p></div> <div class=x title="eng glo oxy">xyzzy</div>',
    'attribute presence selector (with literal escape)';

is run('[ti\\74le]', '<p title>b</p>'), '<div id=irrelevant>1 2 3</div> <div class="x y"><p title>xyzzy</p></div> <div class=x title="eng glo oxy">xyzzy</div>',
    'attribute presence selector (with short hex escape)';

is run('[tit\\00006ce]', '<p title>b</p>'), '<div id=irrelevant>1 2 3</div> <div class="x y"><p title>xyzzy</p></div> <div class=x title="eng glo oxy">xyzzy</div>',
    'attribute presence selector (With long hex escape)';

is run('[tit\\6c e]', '<p title>b</p>'), '<div id=irrelevant>1 2 3</div> <div class="x y"><p title>xyzzy</p></div> <div class=x title="eng glo oxy">xyzzy</div>',
    'attribute presence selector (With short hex escape and space)';

is run('[tit\\00006c e]', '<p title>b</p>'), '<div id=irrelevant>1 2 3</div> <div class="x y"><p title>xyzzy</p></div> <div class=x title="eng glo oxy">xyzzy</div>',
    'attribute presence selector (With long hex escape and space)';

is run('[title=a]', '<p title=a>b</p>'), wrapped('<p title=a>xyzzy</p>'),
    'attribute value selector (unquoted)';

is run('[title="a"]', '<p title=a>b</p>'), wrapped('<p title=a>xyzzy</p>'),
    'attribute value selector (double quoted)';

is run("[title='a']", '<p title=a>b</p>'), wrapped('<p title=a>xyzzy</p>'),
    'attribute value selector (single quoted)';

is run('[title^=""]', '<p title=a>b</p>'), wrapped('<p title=a>b</p>'),
    'attribute prefix selector (empty)';

is run('[title^=xy]', '<p title=xylophone>b</p>'), wrapped('<p title=xylophone>xyzzy</p>'),
    'attribute prefix selector (unquoted)';

is run('[title^=\\x\\y]', '<p title=xylophone>b</p>'), wrapped('<p title=xylophone>xyzzy</p>'),
    'attribute prefix selector (unquoted with literal escape)';

is run('[title^=\\78y]', '<p title=xylophone>b</p>'), wrapped('<p title=xylophone>xyzzy</p>'),
    'attribute prefix selector (unquoted with short hex escape)';

is run('[title^=\\000078y]', '<p title=xylophone>b</p>'), wrapped('<p title=xylophone>xyzzy</p>'),
    'attribute prefix selector (unquoted with long hex escape)';

is run('[title^=\\78 y]', '<p title=xylophone>b</p>'), wrapped('<p title=xylophone>xyzzy</p>'),
    'attribute prefix selector (unquoted with short hex escape and space)';

is run('[title^=\\000078 y]', '<p title=xylophone>b</p>'), wrapped('<p title=xylophone>xyzzy</p>'),
    'attribute prefix selector (unquoted with long hex escape and space)';

is run('[title^="xy"]', '<p title=xylophone>b</p>'), wrapped('<p title=xylophone>xyzzy</p>'),
    'attribute prefix selector (double quoted)';

is run('[title^="\\x\\y"]', '<p title=xylophone>b</p>'), wrapped('<p title=xylophone>xyzzy</p>'),
    'attribute prefix selector (double quoted with literal escape)';

is run('[title^="\\78y"]', '<p title=xylophone>b</p>'), wrapped('<p title=xylophone>xyzzy</p>'),
    'attribute prefix selector (double quoted with short hex escape)';

is run('[title^="\\000078y"]', '<p title=xylophone>b</p>'), wrapped('<p title=xylophone>xyzzy</p>'),
    'attribute prefix selector (double quoted with long hex escape)';

is run('[title^="\\78 y"]', '<p title=xylophone>b</p>'), wrapped('<p title=xylophone>xyzzy</p>'),
    'attribute prefix selector (double quoted with short hex escape and space)';

is run('[title^="\\000078 y"]', '<p title=xylophone>b</p>'), wrapped('<p title=xylophone>xyzzy</p>'),
    'attribute prefix selector (double quoted with long hex escape and space)';

is run("[title^='xy']", '<p title=xylophone>b</p>'), wrapped('<p title=xylophone>xyzzy</p>'),
    'attribute prefix selector (single quoted)';

is run('[title$=""]', '<p title=a>b</p>'), wrapped('<p title=a>b</p>'),
    'attribute suffix selector (empty)';

is run('[title$=ne]', '<p title=xylophone>b</p>'), wrapped('<p title=xylophone>xyzzy</p>'),
    'attribute suffix selector (unquoted)';

is run('[title$="ne"]', '<p title=xylophone>b</p>'), wrapped('<p title=xylophone>xyzzy</p>'),
    'attribute suffix selector (double quoted)';

is run("[title\$='ne']", '<p title=xylophone>b</p>'), wrapped('<p title=xylophone>xyzzy</p>'),
    'attribute suffix selector (single quoted)';

is run('[title*=""]', '<p title=a>b</p>'), wrapped('<p title=a>b</p>'),
    'attribute infix selector (empty)';

is run('[title*=yl]', '<p title=xylophone>b</p>'), wrapped('<p title=xylophone>xyzzy</p>'),
    'attribute infix selector (unquoted)';

is run('[title*="yl"]', '<p title=xylophone>b</p>'), wrapped('<p title=xylophone>xyzzy</p>'),
    'attribute infix selector (double quoted)';

is run("[title*='yl']", '<p title=xylophone>b</p>'), wrapped('<p title=xylophone>xyzzy</p>'),
    'attribute infix selector (single quoted)';

is run('[title~=xy]', '<p title="xy lo phone">b</p>'), wrapped('<p title="xy lo phone">xyzzy</p>'),
    'attribute word selector (unquoted)';

is run('[title~="lo"]', '<p title="xy lo phone">b</p>'), wrapped('<p title="xy lo phone">xyzzy</p>'),
    'attribute word selector (double quoted)';

is run("[title~='phone']", '<p title="xy lo phone">b</p>'), wrapped('<p title="xy lo phone">xyzzy</p>'),
    'attribute word selector (single quoted)';

is run('[title~="xy lo"]', '<p title="xy lo phone">b</p>'), wrapped('<p title="xy lo phone">b</p>'),
    'attribute word selector (bogus)';

is run('[title|=en]', '<p title=en>b</p>'), wrapped('<p title=en>xyzzy</p>'),
    'attribute language prefix selector (unquoted, exact)';

is run('[title|="en"]', '<p title=en-fr>b</p>'), wrapped('<p title=en-fr>xyzzy</p>'),
    'attribute language prefix selector (double quoted, prefix)';

is run('.glow', '<p class="static glow">b</p>'), wrapped('<p class="static glow">xyzzy</p>'),
    'class selector';

is run('.\\gl\\ow', '<p class="static glow">b</p>'), wrapped('<p class="static glow">xyzzy</p>'),
    'class selector (with literal escape)';

is run('.\\67l\\6fw', '<p class="static glow">b</p>'), wrapped('<p class="static glow">xyzzy</p>'),
    'class selector (with short hex escape)';

is run('.\\000067l\\00006fw', '<p class="static glow">b</p>'), wrapped('<p class="static glow">xyzzy</p>'),
    'class selector (with long hex escape)';

is run('.\\67 l\\6f w', '<p class="static glow">b</p>'), wrapped('<p class="static glow">xyzzy</p>'),
    'class selector (with short hex escape and space)';

is run('.\\000067 l\\00006f w', '<p class="static glow">b</p>'), wrapped('<p class="static glow">xyzzy</p>'),
    'class selector (with long hex escape and space)';

is run('#it', '<p id=it>b</p>'), wrapped('<p id=it>xyzzy</p>'),
    'identity selector';

is run('#\\i\\t', '<p id=it>b</p>'), wrapped('<p id=it>xyzzy</p>'),
    'identity selector (with literal escape)';

is run('#\\69t', '<p id=it>b</p>'), wrapped('<p id=it>xyzzy</p>'),
    'identity selector (with short hex escape)';

is run('#\\000069t', '<p id=it>b</p>'), wrapped('<p id=it>xyzzy</p>'),
    'identity selector (with long hex escape)';

is run('#\\69 t', '<p id=it>b</p>'), wrapped('<p id=it>xyzzy</p>'),
    'identity selector (with short hex escape and space)';

is run('#\\000069 t', '<p id=it>b</p>'), wrapped('<p id=it>xyzzy</p>'),
    'identity selector (with long hex escape and space)';

is run('p:nth-child(2)', '<div> <p>A</p> <p>B</p> <p>C</p> <p>D</p> <p>E</p> </div>'), wrapped('<div> <p>A</p> <p>xyzzy</p> <p>C</p> <p>D</p> <p>E</p> </div>'),
    'nth child selector (fixed)';

is run('p:nth-child(odd)', '<div> <p>A</p> <p>B</p> <p>C</p> <p>D</p> <p>E</p> </div>'), wrapped('<div> <p>xyzzy</p> <p>B</p> <p>xyzzy</p> <p>D</p> <p>xyzzy</p> </div>'),
    'nth child selector (odd)';

is run('p:nth-child(eVeN)', '<div> <p>A</p> <p>B</p> <p>C</p> <p>D</p> <p>E</p> </div>'), wrapped('<div> <p>A</p> <p>xyzzy</p> <p>C</p> <p>xyzzy</p> <p>E</p> </div>'),
    'nth child selector (eVeN)';

is run('p:nth-child(2N+3)', '<div> <p>A</p> <p>B</p> <p>C</p> <p>D</p> <p>E</p> </div>'), wrapped('<div> <p>A</p> <p>B</p> <p>xyzzy</p> <p>D</p> <p>xyzzy</p> </div>'),
    'nth child selector (2N+3)';

is run('p:nth-child( -n + 2 )', '<div> <p>A</p> <p>B</p> <p>C</p> <p>D</p> <p>E</p> </div>'), wrapped('<div> <p>xyzzy</p> <p>xyzzy</p> <p>C</p> <p>D</p> <p>E</p> </div>'),
    'nth child selector ( -n + 2 )';

is run('p:nth-child(-n+3)', '<div> <p>A1</p> </div> <div> <p>B1</p> <p>B2</p> </div> <div> <p>C1</p> <p>C2</p> <p>C3</p> </div> <div> <p>D1</p> <p>D2</p> <p>D3</p> <p>D4</p> </div>'),
    wrapped('<div> <p>xyzzy</p> </div> <div> <p>xyzzy</p> <p>xyzzy</p> </div> <div> <p>xyzzy</p> <p>xyzzy</p> <p>xyzzy</p> </div> <div> <p>xyzzy</p> <p>xyzzy</p> <p>xyzzy</p> <p>D4</p> </div>'),
    'nth child selector (-n+3)';

is run('p:nth-child(n+3)', '<div> <p>A</p> <p>B</p> <p>C</p> <p>D</p> <p>E</p> </div>'), wrapped('<div> <p>A</p> <p>B</p> <p>xyzzy</p> <p>xyzzy</p> <p>xyzzy</p> </div>'),
    'nth child selector (n+3)';

is run('p:nth-child(4n+1)', '<div> <p>A</p> <p>B</p> <p>C</p> <p>D</p> <p>E</p> </div>'), wrapped('<div> <p>xyzzy</p> <p>B</p> <p>C</p> <p>D</p> <p>xyzzy</p> </div>'),
    'nth child selector (4n+1)';

is run('p:nth-child(4n-3)', '<div> <p>A</p> <p>B</p> <p>C</p> <p>D</p> <p>E</p> </div>'), wrapped('<div> <p>xyzzy</p> <p>B</p> <p>C</p> <p>D</p> <p>xyzzy</p> </div>'),
    'nth child selector (4n-3)';

is run('p:nth-of-type(2)', '<div> <br> <p>A</p> <p>B</p> <br> <br> <p>C</p> <br> <p>D</p> <p>E</p> </div>'), wrapped('<div> <br> <p>A</p> <p>xyzzy</p> <br> <br> <p>C</p> <br> <p>D</p> <p>E</p> </div>'),
    'nth of type selector (fixed)';

is run('p:nth-of-type(odd)', '<div> <br> <p>A</p> <p>B</p> <br> <br> <p>C</p> <br> <p>D</p> <p>E</p> </div>'), wrapped('<div> <br> <p>xyzzy</p> <p>B</p> <br> <br> <p>xyzzy</p> <br> <p>D</p> <p>xyzzy</p> </div>'),
    'nth of type selector (odd)';

is run('p:nth-of-type(even)', '<div> <br> <p>A</p> <p>B</p> <br> <br> <p>C</p> <br> <p>D</p> <p>E</p> </div>'), wrapped('<div> <br> <p>A</p> <p>xyzzy</p> <br> <br> <p>C</p> <br> <p>xyzzy</p> <p>E</p> </div>'),
    'nth of type selector (even)';

is run('p:nth-of-type(2N+3)', '<div> <br> <p>A</p> <p>B</p> <br> <br> <p>C</p> <br> <p>D</p> <p>E</p> </div>'), wrapped('<div> <br> <p>A</p> <p>B</p> <br> <br> <p>xyzzy</p> <br> <p>D</p> <p>xyzzy</p> </div>'),
    'nth of type selector (2N+3)';

is run('p:nth-of-type( -n + 2 )', '<div> <br> <p>A</p> <p>B</p> <br> <br> <p>C</p> <br> <p>D</p> <p>E</p> </div>'), wrapped('<div> <br> <p>xyzzy</p> <p>xyzzy</p> <br> <br> <p>C</p> <br> <p>D</p> <p>E</p> </div>'),
    'nth of type selector ( -n + 2 )';

is run('p:nth-of-type(n+3)', '<div> <br> <p>A</p> <p>B</p> <br> <br> <p>C</p> <br> <p>D</p> <p>E</p> </div>'), wrapped('<div> <br> <p>A</p> <p>B</p> <br> <br> <p>xyzzy</p> <br> <p>xyzzy</p> <p>xyzzy</p> </div>'),
    'nth of type selector (n+3)';

is run('p:nth-of-type(4n+1)', '<div> <br> <p>A</p> <p>B</p> <br> <br> <p>C</p> <br> <p>D</p> <p>E</p> </div>'), wrapped('<div> <br> <p>xyzzy</p> <p>B</p> <br> <br> <p>C</p> <br> <p>D</p> <p>xyzzy</p> </div>'),
    'nth of type selector (4n+1)';

is run('p:nth-of-type(4n-3)', '<div> <br> <p>A</p> <p>B</p> <br> <br> <p>C</p> <br> <p>D</p> <p>E</p> </div>'), wrapped('<div> <br> <p>xyzzy</p> <p>B</p> <br> <br> <p>C</p> <br> <p>D</p> <p>xyzzy</p> </div>'),
    'nth of type selector (4n-3)';

is run('p:first-child', '<div> <p>A</p> <p>B</p> <p>C</p> <p>D</p> <p>E</p> </div>'), wrapped('<div> <p>xyzzy</p> <p>B</p> <p>C</p> <p>D</p> <p>E</p> </div>'),
    'first child selector';

is run('p:first-of-type', '<div> <br> <p>A</p> <p>B</p> <br> <br> <p>C</p> <br> <p>D</p> <p>E</p> </div>'), wrapped('<div> <br> <p>xyzzy</p> <p>B</p> <br> <br> <p>C</p> <br> <p>D</p> <p>E</p> </div>'),
    'first of type selector';

is run(':not(div)', '<p title=a>b</p>'), wrapped('<p title=a>xyzzy</p>'),
    'negated type selector';

is run(':not([id]):not([class])', '<p title=a>b</p>'), wrapped('<p title=a>xyzzy</p>'),
    'negated attribute presence selector';

is run('.foo[title], #bar', '<div class=foo>A</div> <div id=bar>B</div> <div class=foo title=asdf>C</div>'), wrapped('<div class=foo>A</div> <div id=bar>xyzzy</div> <div class=foo title=asdf>xyzzy</div>'),
    'selector list';

done_testing;
