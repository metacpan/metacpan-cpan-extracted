use strict;
use warnings;
use Test::More;
use HTML::Blitz ();
use HTML::Blitz::Builder qw(mk_elem fuse_fragment);

my $prefix = '<div id=irrelevant>1 2 3</div> <div class="x y">';
my $suffix = '</div> <div class=x title="eng glo oxy"> &amp; </div>';

sub wrapped {
    $prefix . $_[0] . $suffix
}

sub run {
    my ($action, $html, $data) = @_;
    my $blitz = HTML::Blitz->new(['#x' => $action]);
    $blitz->apply_to_html('(test)', wrapped $html)->process($data // ())
}

my $html = '<div id=x title=a><hr><p>b</p></div>';
is run(['remove'], $html),
    wrapped(''),
    'remove';

is run(['remove_inner'], $html),
    wrapped('<div id=x title=a></div>'),
    'remove_inner';

is run(['remove_if', 'cond'], $html, { cond => 0 }),
    wrapped($html),
    'remove_if (false)';

is run(['remove_if', 'cond'], $html, { cond => 1 }),
    wrapped(''),
    'remove_if (true)';

is run(['replace_inner_text', 'xyzzy'], $html),
    wrapped('<div id=x title=a>xyzzy</div>'),
    'replace_inner_text';

is run(['replace_inner_var', 'var'], $html, { var => 'xyzzy' }),
    wrapped('<div id=x title=a>xyzzy</div>'),
    'replace_inner_var';

my $subtemplate = HTML::Blitz->new(['*' => ['replace_inner_var', 'var']])->apply_to_html('(inner)', '<p>A</p> <p>B</p>');
is run(['replace_inner_template', $subtemplate], $html, { var => 'xyzzy' }),
    wrapped('<div id=x title=a><p>xyzzy</p> <p>xyzzy</p></div>'),
    'replace_inner_template';

is run(['replace_inner_dyn_builder', 'var'], $html, { var => fuse_fragment('a ', mk_elem('hr'), ' b') }),
    wrapped('<div id=x title=a>a <hr> b</div>'),
    'replace_inner_dyn_builder';

is run(['replace_outer_text', 'xyzzy'], $html),
    wrapped('xyzzy'),
    'replace_outer_text';

is run(['replace_outer_var', 'var'], $html, { var => 'xyzzy' }),
    wrapped('xyzzy'),
    'replace_outer_var';

is run(['replace_outer_template', $subtemplate], $html, { var => 'xyzzy' }),
    wrapped('<p>xyzzy</p> <p>xyzzy</p>'),
    'replace_outer_template';

is run(['replace_outer_dyn_builder', 'var'], $html, { var => fuse_fragment('a ', mk_elem('hr'), ' b') }),
    wrapped('a <hr> b'),
    'replace_outer_dyn_builder';

is run(['transform_inner_sub', sub { "($_[0])" }], $html),
    wrapped('<div id=x title=a>(b)</div>'),
    'transform_inner_sub';

is run(['transform_inner_var', 'func'], $html, { func => sub { "($_[0])" } }),
    wrapped('<div id=x title=a>(b)</div>'),
    'transform_inner_var';

is run(['transform_outer_sub', sub { "($_[0])" }], $html),
    wrapped('(b)'),
    'transform_outer_sub';

is run(['transform_outer_var', 'func'], $html, { func => sub { "($_[0])" } }),
    wrapped('(b)'),
    'transform_outer_var';

is run(['remove_attribute', 'title'], $html),
    wrapped('<div id=x><hr><p>b</p></div>'),
    'remove_attribute (single)';

is run(['remove_attribute', 'title', 'id'], $html),
    wrapped('<div><hr><p>b</p></div>'),
    'remove_attribute (multiple)';

is run(['remove_all_attributes'], $html),
    wrapped('<div><hr><p>b</p></div>'),
    'remove_all_attributes';

is run(['replace_all_attributes', { id => [text => 'foo'], class => [var => 'bar'] }], $html, { bar => 'qu ux' }),
    wrapped('<div class="qu ux" id=foo><hr><p>b</p></div>'),
    'replace_all_attributes';

is run(['set_attribute_text', title => 'xyzzy'], $html),
    wrapped('<div id=x title=xyzzy><hr><p>b</p></div>'),
    'set_attribute_text (single existing)';

is run(['set_attribute_text', class => 'xyzzy'], $html),
    wrapped('<div class=xyzzy id=x title=a><hr><p>b</p></div>'),
    'set_attribute_text (single new)';

is run(['set_attribute_text', { title => 'quux', class => 'xyzzy' }], $html),
    wrapped('<div class=xyzzy id=x title=quux><hr><p>b</p></div>'),
    'set_attribute_text (multiple)';

is run(['set_attribute_var', title => 'var'], $html, { var => 'xyzzy' }),
    wrapped('<div id=x title="xyzzy"><hr><p>b</p></div>'),
    'set_attribute_var (single existing)';

is run(['set_attribute_var', class => 'var'], $html, { var => 'xyzzy' }),
    wrapped('<div class="xyzzy" id=x title=a><hr><p>b</p></div>'),
    'set_attribute_var (single new)';

is run(['set_attribute_var', { title => 't', class => 'c' }], $html, { t => 'quux', c => 'xyzzy' }),
    wrapped('<div class="xyzzy" id=x title="quux"><hr><p>b</p></div>'),
    'set_attribute_var (multiple)';

is run(['set_attributes', { id => [text => 'foo'], class => [var => 'bar'] }], $html, { bar => 'qu ux' }),
    wrapped('<div class="qu ux" id=foo title=a><hr><p>b</p></div>'),
    'set_attributes';

is run(['transform_attribute_sub', title => sub { defined($_[0]) ? "($_[0])" : "xyzzy" }], $html),
    wrapped('<div id=x title=(a)><hr><p>b</p></div>'),
    'transform_attribute_sub (existent -> transformed)';

is run(['transform_attribute_sub', class => sub { defined($_[0]) ? "($_[0])" : "xyzzy" }], $html),
    wrapped('<div class=xyzzy id=x title=a><hr><p>b</p></div>'),
    'transform_attribute_sub (non-existent -> created)';

is run(['transform_attribute_sub', title => sub {}], $html),
    wrapped('<div id=x><hr><p>b</p></div>'),
    'transform_attribute_sub (existent -> removed)';

is run(['transform_attribute_sub', class => sub {}], $html),
    wrapped('<div id=x title=a><hr><p>b</p></div>'),
    'transform_attribute_sub (non-existent -> unchanged)';

is run(['transform_attribute_var', title => 'func'], $html, { func => sub { defined($_[0]) ? "($_[0])" : "xyzzy" } }),
    wrapped('<div id=x title="(a)"><hr><p>b</p></div>'),
    'transform_attribute_var (existent -> transformed)';

is run(['transform_attribute_var', class => 'func'], $html, { func => sub { defined($_[0]) ? "($_[0])" : "xyzzy" } }),
    wrapped('<div class="xyzzy" id=x title=a><hr><p>b</p></div>'),
    'transform_attribute_var (non-existent -> created)';

is run(['transform_attribute_var', title => 'func'], $html, { func => sub {} }),
    wrapped('<div id=x><hr><p>b</p></div>'),
    'transform_attribute_var (existent -> removed)';

is run(['transform_attribute_var', class => 'func'], $html, { func => sub {} }),
    wrapped('<div id=x title=a><hr><p>b</p></div>'),
    'transform_attribute_var (non-existent -> unchanged)';

is run(['add_attribute_word', class => qw(mano a mano)], $html),
    wrapped('<div class="mano a" id=x title=a><hr><p>b</p></div>'),
    'add_attribute_word (created)';

is run(['add_attribute_word', title => qw(mano a mano)], $html),
    wrapped('<div id=x title="a mano"><hr><p>b</p></div>'),
    'add_attribute_word (added)';

is run(['remove_attribute_word', class => qw(mano a mano)], $html),
    wrapped('<div id=x title=a><hr><p>b</p></div>'),
    'remove_attribute_word (nonexistent)';

is run(['remove_attribute_word', title => qw(mano a mano)], $html),
    wrapped('<div id=x><hr><p>b</p></div>'),
    'remove_attribute_word (eviscerated)';

is run(['remove_attribute_word', class => qw(mano a mano panama! plan)], '<div class="a man, a plan, a canal, panama!" id=x title=a><hr><p>b</p></div>'),
    wrapped('<div class="man, plan, canal," id=x title=a><hr><p>b</p></div>'),
    'remove_attribute_word (mixed)';

is run(['add_class', qw(mano a mano)], $html),
    wrapped('<div class="mano a" id=x title=a><hr><p>b</p></div>'),
    'add_class (created)';

is run(['add_class', qw(mano a mano)], '<div class="a? mano" id=x title=a><hr><p>b</p></div>'),
    wrapped('<div class="a? mano a" id=x title=a><hr><p>b</p></div>'),
    'add_class (added)';

is run(['remove_class', qw(mano a mano)], $html),
    wrapped('<div id=x title=a><hr><p>b</p></div>'),
    'remove_class (nonexistent)';

is run(['remove_class', qw(mano a mano)], '<div class="a mano a a a" id=x title=a><hr><p>b</p></div>'),
    wrapped('<div id=x title=a><hr><p>b</p></div>'),
    'remove_class (eviscerated)';

is run(['remove_class', qw(mano a mano panama! plan)], '<div class="a man, a plan, a canal, panama!" id=x title=a><hr><p>b</p></div>'),
    wrapped('<div class="man, plan, canal," id=x title=a><hr><p>b</p></div>'),
    'remove_class (mixed)';

is run(['repeat_outer', items => \['set_attribute_var', id => 'id'], ['p' => ['replace_inner_var', 'p']]], $html, { items => [{ id => 'x1', p => 'p1' }, { id => 'x2', p => 'p2' }] }),
    wrapped('<div id="x1" title=a><hr><p>p1</p></div><div id="x2" title=a><hr><p>p2</p></div>'),
    'repeat_outer';

is run(['repeat_inner', items => ['hr' => ['separator']], ['p' => ['replace_inner_var', 'p']]], $html, { items => [{ p => 'p1' }, { p => 'p2' }] }),
    wrapped('<div id=x title=a><p>p1</p><hr><p>p2</p></div>'),
    'repeat_inner';

done_testing;
