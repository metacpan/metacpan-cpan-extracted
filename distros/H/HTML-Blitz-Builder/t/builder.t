use Test2::V0;
use HTML::Blitz::Builder qw(
    mk_doctype
    mk_comment
    mk_elem
    to_html
    fuse_fragment
);

is to_html(mk_doctype), '<!DOCTYPE html>', "mk_doctype works";
is to_html(fuse_fragment mk_doctype), '<!DOCTYPE html>', "mk_doctype (fused) works";

is to_html(mk_comment 'hello, world'), '<!--hello, world-->', "mk_comment works";
is to_html(fuse_fragment mk_comment 'hello, world'), '<!--hello, world-->', "mk_comment (fused) works";
like dies { mk_comment '>asdf<' }, qr/^HTML comment cannot start with '>'/, "mk_comment throws on '>...'";
like dies { mk_comment '->asdf<-' }, qr/^HTML comment cannot start with '->'/, "mk_comment throws on '->...'";
like dies { mk_comment 'foo<!--bar' }, qr/^HTML comment cannot contain '<!--'/, "mk_comment throws on '...<!--...'";
like dies { mk_comment 'foo--!>bar' }, qr/^HTML comment cannot contain '--!>'/, "mk_comment throws on '...--!>...'";
like dies { mk_comment 'foo-->bar' }, qr/^HTML comment cannot contain '-->'/, "mk_comment throws on '...-->...'";

is to_html(mk_elem 'p'), '<p></p>', 'basic element';
is to_html(mk_elem 'br'), '<br>', 'basic void element';
is to_html(mk_elem 'br', fuse_fragment), '<br>', 'basic void element with fused empty children';
is to_html(mk_elem 'br', fuse_fragment fuse_fragment), '<br>', 'basic void element with fused empty children (fused)';
like dies { mk_elem 'br', mk_elem 'span' }, qr/^<br> tag cannot have contents/, 'void element cannot contain elements';
like dies { mk_elem 'br', 'x' }, qr/^<br> tag cannot have contents/, 'void element cannot contain text';

{
    my @fragment = (
        '<g>',
        mk_elem('p', { class => 'para' },
            'foo',
            mk_elem('span', { title => "A <3 B & C" },
                'bar',
            ),
            'baz',
        ),
    );

    my $html = '&lt;g><p class=para>foo<span title="A <3 B &amp; C">bar</span>baz</p>';

    is
        to_html(@fragment),
        $html,
        "nested elements with attributes";

    is
        to_html(fuse_fragment @fragment),
        $html,
        "nested elements with attributes (fused)";
}

is to_html(mk_elem 'style', '&&&'), '<style>&&&</style>', "basic <style>";
is to_html(mk_elem 'style', '</style'), '<style></style</style>', "weird '</style' works";
like dies { mk_elem 'style', mk_comment '' }, qr{^<style> tag cannot have child elements}, "<style> cannot contain HTML comment";
like dies { mk_elem 'style', '</style ' }, qr{tag cannot contain '</style '}, "style containing '</style ' throws";
like dies { mk_elem 'style', '</style/' }, qr{tag cannot contain '</style/'}, "style containing '</style/' throws";

is to_html(mk_elem 'script', '&&&'), '<script>&&&</script>', "basic <script>";
is to_html(mk_elem 'script', '</script'), '<script></script</script>', "weird '</script' works";
is to_html(mk_elem 'script', 'a', fuse_fragment('b', fuse_fragment('c', 'd')), 'e'), '<script>abcde</script>', "<script> with fused text works";
like dies { mk_elem 'script', mk_comment '' }, qr{^<script> tag cannot have child elements}, "<script> cannot contain HTML comment";
like dies { mk_elem 'script', '</script ' }, qr{tag cannot contain '</script '}, "script containing '</script ' throws";
like dies { mk_elem 'script', '</script/' }, qr{tag cannot contain '</script/'}, "script containing '</script/' throws";
for my $torcher (
    [1, '<script>'],
    [1, '</script'],
    [0, '</script>'],
    [0, '</script/'],
    [0, '</script '],
    [1, '</scriptn'],
    [1, ' <!-- '],
    [1, ' <!--> <script> '],
    [1, ' <!---> <script> '],
    [1, ' <!----> <script> '],
    [1, ' <!-- --> <script> '],
    [0, ' <!-- <script> '],
    [1, ' <!-- <script -->'],
    [1, ' <!-- <script> -->'],
    [1, ' <!-- <script> </script>'],
    [1, ' <!-- <script </script '],
    [0, ' <!-- <script> --> </script> '],
) {
    my ($good, $fragment) = @$torcher;
    if ($good) {
        is to_html(mk_elem 'script', $fragment), "<script>$fragment</script>", "'<script>$fragment</script>' is valid";
    } else {
        like dies { mk_elem 'script', $fragment }, qr/<script> tag cannot contain/, "'<script>$fragment</script>' throws";
    }
}

is to_html, '', 'empty';
is to_html(fuse_fragment), '', 'empty fused fragment';

{
    my $ref = [];
    is to_html($ref), "$ref", "references get stringified";
    is to_html($ref, $ref), "$ref$ref", "references get stringified (2)";
    is to_html(mk_elem 'title', $ref), "<title>$ref</title>", "references as children of <title>";
    is to_html(mk_elem 'title', $ref, $ref), "<title>$ref$ref</title>", "references as children of <title> (2)";
}
{
    my $ref = bless [], __PACKAGE__;
    is to_html($ref), "$ref", "blessed references get stringified";
    is to_html($ref, $ref), "$ref$ref", "blessed references get stringified (2)";
    is to_html(mk_elem 'title', $ref), "<title>$ref</title>", "blessed references as children of <title>";
    is to_html(mk_elem 'title', $ref, $ref), "<title>$ref$ref</title>", "blessed references as children of <title> (2)";
}

subtest 'builder objects are immutable', sub {
    my $div_a = mk_elem 'div', 'a';
    my $div_b = mk_elem 'div', 'b';
    my $div_c = mk_elem 'div', $div_a, 'c', $div_a;
    my $fused = fuse_fragment $div_a, $div_b, $div_c, $div_a;
    is to_html($div_a, $div_b, $div_c, $div_a), '<div>a</div><div>b</div><div><div>a</div>c<div>a</div></div><div>a</div>';
    is to_html($fused), '<div>a</div><div>b</div><div><div>a</div>c<div>a</div></div><div>a</div>';
    is to_html($div_a), '<div>a</div>';
};

done_testing;
