use Test2::V0;
use Test2::API qw(context_do);
use JSON::PP qw(encode_json decode_json);
use HTML::Blitz::Builder qw(
    mk_doctype
    mk_comment
    mk_elem
    to_html
    fuse_fragment
);

sub xmarshal {
    my ($obj, $expected, $name) = @_;
    context_do {
        my $ctx = shift;
        my $json = encode_json [$obj->FREEZE('JSON')];
        $ctx->note("JSON: $json");
        my @values = @{decode_json $json};
        my $obj_new = ref($obj)->THAW('JSON', @values);
        my $html = to_html $obj;
        my $html_new = to_html $obj_new;
        if ($html eq $expected) {
            $ctx->pass("[original] $name");
        } else {
            $ctx->fail("[original] $name", "got: $html", "expected: $expected");
        }
        if ($html_new eq $expected) {
            $ctx->pass("[deserialized] $name");
        } else {
            $ctx->fail("[deserialized] $name", "got: $html_new", "expected: $expected");
        }
        $obj_new
    }
}

xmarshal fuse_fragment, '', 'fused empty fragment';
xmarshal fuse_fragment(''), '', 'fused empty string';
xmarshal fuse_fragment('a', '<', 'b'), 'a&lt;b', 'fused string';
xmarshal mk_doctype, '<!DOCTYPE html>', 'doctype';
xmarshal fuse_fragment(mk_doctype), '<!DOCTYPE html>', 'fused doctype';
xmarshal mk_comment('&'), '<!--&-->', 'comment';
xmarshal fuse_fragment(mk_comment '&'), '<!--&-->', 'fused comment';
xmarshal mk_elem('hr'), '<hr>', 'void element';
xmarshal fuse_fragment(mk_elem 'hr'), '<hr>', 'fused void element';
xmarshal mk_elem('title', 'a<b'), '<title>a&lt;b</title>', 'childless element';
xmarshal fuse_fragment(mk_elem 'title', 'a<b'), '<title>a&lt;b</title>', 'fused childless element';
xmarshal mk_elem('style', 'a<b'), '<style>a<b</style>', 'style element';
xmarshal fuse_fragment(mk_elem 'style', 'a<b'), '<style>a<b</style>', 'fused style element';
xmarshal mk_elem('script', 'a<b'), '<script>a<b</script>', 'script element';
xmarshal fuse_fragment(mk_elem 'script', 'a<b'), '<script>a<b</script>', 'fused script element';
xmarshal mk_elem('div', mk_elem('img', { src => 'kitten.jpg', alt => 'a kitten' }), 'cute'),
    '<div><img alt="a kitten" src=kitten.jpg>cute</div>',
    'general element';
xmarshal fuse_fragment(mk_elem('div', mk_elem('img', { src => 'kitten.jpg', alt => 'a kitten' }), 'cute')),
    '<div><img alt="a kitten" src=kitten.jpg>cute</div>',
    'fused general element';
xmarshal fuse_fragment(fuse_fragment, 'a', mk_comment('b'), mk_elem('span', 'c'), mk_comment('d'), 'e', fuse_fragment),
    'a<!--b--><span>c</span><!--d-->e',
    'fused mixed bag';

done_testing;
