use strict;
use warnings;
use Test::Most;
use Test::Deep;
use Fern qw(tag empty_element_tag render_tag);

for my $tag_name (qw(
    br
    hr
    input
))
{
    is_deeply([empty_element_tag($tag_name)->()], ['<' . $tag_name . ' />'], $tag_name);
}

for my $tag_name (qw(
    a
    abbr
    acronym
    address
    area
    b
    base
    bdo
    big
    blockquote
    body
    button
    caption
    cite
    code
    col
    colgroup
    dd
    del
    div
    dfn
    dl
    dt
    em
    fieldset
    form
    h1
    h2
    h3
    h4
    h5
    h6
    head
    html
    i
    img
    ins
    kbd
    label
    legend
    li
    link
    map
    meta
    noscript
    object
    ol
    optgroup
    option
    p
    param
    pre
    q
    samp
    script
    select
    small
    span
    strong
    style
    sub
    sup
    table
    tbody
    td
    textarea
    tfoot
    th
    thead
    title
    tr
    tt
    ul
    var
))
{
    is(render_tag(tag($tag_name)), '<' . $tag_name . '></' . $tag_name . '>', $tag_name);
}

is(render_tag(tag('div', {random => 'lala'})), '<div random="lala"></div>', 'Attributes');
is(render_tag(tag('div', {class => 'foo'}, tag('div', {class => 'bar'}, tag('div')))), '<div class="foo"><div class="bar"><div></div></div></div>', 'Containment');
is(render_tag(tag('div', [class => 'foo', name => 'foofoo'], 'Test')), '<div class="foo" name="foofoo">Test</div>', 'Ordered attributes');

my $got = render_tag(
    tag('div', {class => 'modal hide fade imp-error-modal'},
        tag('div', {class => 'modal-header'},
            tag('button', {type => 'button', class => 'close', 'data-dismiss' => 'modal'}, '×'),
              tag('h3', 'A JavaScript error has occurred')),
          tag('div', {class => 'modal-body'},
            tag('p', "Please click the &quot;Open RT&quot; button to open an RT window and submit the error.",
                "Add to the ticket how we can reproduce this error."),
              tag('h4', 'Error Info'),
              tag('pre', 'info')),
          tag('div', {class => 'modal-footer'},
            tag('a', {href => '#', class => 'btn', 'data-dismiss' => 'modal'},
                'Ignore'),
              tag('a', {href => '#', class => 'btn btn-primary'},
                'Open RT')))
);

my $expected = '<div class="modal hide fade imp-error-modal"><div class="modal-header"><button .*>×</button><h3>A JavaScript error has occurred</h3></div><div class="modal-body"><p>Please click the &quot;Open RT&quot; button to open an RT window and submit the error.Add to the ticket how we can reproduce this error.</p><h4>Error Info</h4><pre>info</pre></div><div class="modal-footer"><a .*>Ignore</a><a .*>Open RT</a></div></div>';

like($got, qr{$expected}, 'Complex example');

is(render_tag(tag('foo')), '<foo></foo>', 'foo tag (not empty-element tag)');
is(render_tag(empty_element_tag('bar')), '<bar />', 'bar tag (empty-element tag)');

sub custom_tag {
    my ($obj, $p1, $p2) = @_;
    return sub {
        return (render_tag(tag('span', 'Class (' . $obj->{class} . ') and Param 1 (' . $p1 . ') and Param 2 (' . $p2 . ')'), @_), {metadata => 5});
    };
}

my $custom_tag_function = tag('div', custom_tag({class => 'this-class'}, 3, 'test'));
is(
    render_tag($custom_tag_function),
    '<div><span>Class (this-class) and Param 1 (3) and Param 2 (test)</span></div>',
    'Custom tag',
);
is(($custom_tag_function->())[1]->{metadata}, 5, 'Metadata');

{
    my $tag_function = tag('div', tag('span', sub{ $_[0], 'apple' }, ' and ', sub { $_ [1], 'banana' }));
    my ($xml, $m1, $m2) = $tag_function->('foo', 4);
    is($xml, '<div><span>foo and 4</span></div>', 'Metadata-filled xml');
    is($m1, 'apple', 'Metadata trickle 1');
    is($m2, 'banana', 'Metadata trickle 2');
}

is(render_tag(tag('div', (1 == 1 ? tag('div') : tag('span')))), '<div><div></div></div>', 'Dynamic tag tree 1');
is(render_tag(tag('div', (1 == 0 ? tag('div') : tag('span')))), '<div><span></span></div>', 'Dynamic tag tree 2');

my $template1 = tag('div', tag('span', sub { $_[0] } ), tag('span', sub { $_[1] }));
is(($template1->('Hello', 'World'))[0], '<div><span>Hello</span><span>World</span></div>', 'Parameter passing in content');

my $template2 = empty_element_tag('div', { fruit => sub { $_[0] } });
is(($template2->('apple', 'number'))[0], '<div fruit="apple" />', 'Parameter passing in tags');

{
    my $xml = render_tag( tag('TAXON_ID', 0) );
    is($xml, '<TAXON_ID>0</TAXON_ID>', 'zero is a value');
}
{
    # I'm not sure if this is what it should do
    # but this is what it currently does
    # so somebody will notice if it changes
    my $xml = render_tag( tag('TAXON_ID', '') );
    is($xml, '<TAXON_ID></TAXON_ID>', 'empty string makes empty tag');
}

done_testing;

