use Test2::V0;
use HTML::Blitz::Builder qw(
    mk_doctype
    mk_comment
    mk_elem
    to_html
    fuse_fragment
);

is to_html(mk_doctype), '<!DOCTYPE html>', "mk_doctype works";

is to_html(mk_comment 'hello, world'), '<!--hello, world-->', "mk_comment works";
like dies { mk_comment '>asdf<' }, qr/comment cannot start with '>'/, "mk_comment throws on '>...'";
like dies { mk_comment '->asdf<-' }, qr/comment cannot start with '->'/, "mk_comment throws on '->...'";
like dies { mk_comment 'foo<!--bar' }, qr/comment cannot contain '<!--'/, "mk_comment throws on '...<!--...'";
like dies { mk_comment 'foo--!>bar' }, qr/comment cannot contain '--!>'/, "mk_comment throws on '...--!>...'";
like dies { mk_comment 'foo-->bar' }, qr/comment cannot contain '-->'/, "mk_comment throws on '...-->...'";

is to_html(mk_elem 'p'), '<p></p>', 'basic element';
is to_html(mk_elem 'br'), '<br>', 'basic void element';

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
like dies { mk_elem 'style', '</style ' }, qr{tag cannot contain '</style '}, "style containing '</style ' throws";
like dies { mk_elem 'style', '</style/' }, qr{tag cannot contain '</style/'}, "style containing '</style/' throws";

is to_html(mk_elem 'script', '&&&'), '<script>&&&</script>', "basic <script>";
is to_html(mk_elem 'script', '</script'), '<script></script</script>', "weird '</script' works";
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

done_testing;
