use strict;
use warnings;
use utf8;
use Test::More;
use Encode qw(encode);
use HTML::Anchor::Audit qw(audit_html audit_utf8);

sub codes { [ map { $_->{code} } @{ $_[0]{issues} } ] }
my $good = '<a href="#intro">Start</a><h2 id="intro">Intro</h2>';
my $r = audit_html($good);
is_deeply(codes($r), [], 'a forward reference resolves');
is($r->{references}[0]{status}, 'matched', 'matched reference reported');
is($r->{references}[0]{target_kind}, 'id', 'ID kind');
is($r->{statistics}{checked_reference_count}, 1, 'one checked reference');
is($good, '<a href="#intro">Start</a><h2 id="intro">Intro</h2>', 'input string untouched');

$r = audit_html('<a href="#gone">Go</a>');
is_deeply(codes($r), ['missing_target'], 'missing target detected');
is($r->{issues}[0]{value}, 'gone', 'missing value');
is($r->{issues}[0]{line}, 1, 'missing location line');
is($r->{issues}[0]{column}, 1, 'missing location column');

$r = audit_html('<h2 id="same"></h2><h3 id="same"></h3><a href="#same"></a>');
is_deeply(codes($r), [qw(duplicate_id ambiguous_target)], 'duplicate and ambiguous reference');
is(scalar @{ $r->{issues}[1]{related} }, 2, 'ambiguous related locations retained');
is($r->{references}[0]{status}, 'ambiguous', 'ambiguous status');
is($r->{issues}[0]{related}[0]{column}, 1, 'original target location');

for my $href ('#العربية', '#%D8%A7%D9%84%D8%B9%D8%B1%D8%A8%D9%8A%D8%A9') {
    $r = audit_html(qq{<a href="$href"></a><h2 id="العربية"></h2>});
    is_deeply(codes($r), [], 'Arabic literal or encoded target resolves');
    is($r->{references}[0]{target_value}, 'العربية', 'Arabic value retained');
}
$r = audit_html('<a href="#a&amp;b"></a><h2 id="a&#38;b"></h2>');
is_deeply(codes($r), [], 'attribute entities resolve');
$r = audit_html('<a href="#&#x1F600;"></a><h2 id="😀"></h2>');
is_deeply(codes($r), [], 'non-BMP numeric entity resolves');
$r = audit_html('<a href="#a+b"></a><h2 id="a b"></h2>');
is_deeply(codes($r), ['missing_target'], 'plus is not space');
$r = audit_html('<a href="#a%2Bb"></a><h2 id="a+b"></h2>');
is_deeply(codes($r), [], 'encoded plus resolves');
$r = audit_html('<a href="#%2561"></a><h2 id="a"></h2>');
is_deeply(codes($r), ['missing_target'], 'no double percent decoding');

$r = audit_html('<a href="#%61"></a><h2 id="%61"></h2><h2 id="a"></h2>');
is($r->{references}[0]{target_value}, '%61', 'exact target before percent decoded target');
$r = audit_html('<a href="#%61"></a><a name="%61"></a><h2 id="a"></h2>');
is($r->{references}[0]{target_kind}, 'name', 'exact legacy name before decoded ID');
$r = audit_html('<a href="#x"></a><a name="x"></a><h2 id="x"></h2>');
is($r->{references}[0]{target_kind}, 'id', 'ID before legacy name within a pass');
$r = audit_html('<a href="#x"></a><a id="x" name="x"></a>');
is_deeply(codes($r), [], 'ID/name on the same element is not ambiguous');
$r = audit_html('<a name="x"></a><a name="x"></a><a href="#x"></a>');
is_deeply(codes($r), ['ambiguous_target'], 'repeated legacy name is not duplicate_id');
$r = audit_html('<div name="x"></div><a href="#x"></a>');
is_deeply(codes($r), ['missing_target'], 'only anchor names count');
$r = audit_html('<h2 id="Intro"></h2><a href="#intro"></a>');
is_deeply(codes($r), ['missing_target'], 'IDs are case sensitive');

for my $href ('#', '#top', '#TOP', '#%74op') {
    $r = audit_html(qq{<a href="$href"></a>});
    is($r->{references}[0]{status}, 'top', 'empty or top special reference');
    is_deeply(codes($r), [], 'special reference clean');
}
$r = audit_html('<h2 id="top"></h2><a href="#top"></a>');
is($r->{references}[0]{status}, 'matched', 'an actual top ID has precedence');
$r = audit_html('<a href="#bad%ZZ"></a><h2 id="bad%ZZ"></h2>');
is_deeply(codes($r), [], 'malformed percent literal can match exactly');
$r = audit_html('<a href="#%FF"></a><h2 id="�"></h2>');
is_deeply(codes($r), [], 'invalid encoded UTF-8 uses replacement in fragment matching');

$r = audit_html('<h2 id="é"></h2><a href="#é"></a>');
is_deeply(codes($r), ['missing_target'], 'canonically equivalent IDs do not silently match');
is_deeply($r->{issues}[0]{normalization_candidates}, ['é'], 'NFC hint suggests existing target');

my $contexts = <<'HTML';
<!-- <h2 id="comment"></h2><a href="#comment"></a> -->
<script>var s = '<a href="#script"></a>';</script>
<style>x::before { content: '<a href="#style"></a>'; }</style>
<textarea><a href="#textarea"></a></textarea>
<title><a href="#title"></a></title>
<template id="template"><h2 id="hidden"></h2><a href="#hidden"></a>
<template><a href="#nested"></a></template></template>
<a href="#template"></a><a href="#hidden"></a>
HTML
$r = audit_html($contexts);
is($r->{statistics}{reference_count}, 2, 'comments, raw text and nested template contents ignored');
is($r->{statistics}{target_count}, 1, 'template element own ID visible');
is_deeply(codes($r), ['missing_target'], 'outside reference cannot reach template content');

$r = audit_html('<base href="https://example.invalid/"><a href="#missing"></a>');
is($r->{references}[0]{status}, 'ignored', 'nonempty base href is conservative');
is($r->{references}[0]{reason}, 'base_href', 'base reason');
is_deeply(codes($r), [], 'no false missing report under a base href');
$r = audit_html('<base href=""><base href="https://example.invalid/"><a href="#missing"></a>');
is_deeply(codes($r), ['missing_target'], 'first base href controls checking');
$r = audit_html('<template><base href="https://example.invalid/"></template><a href="#missing"></a>');
is_deeply(codes($r), ['missing_target'], 'base in template is inactive');
$r = audit_html('<a href="#id:~:text=hello"></a>');
is($r->{references}[0]{reason}, 'fragment_directive', 'text directive explicitly ignored');
$r = audit_html('<a href="other.html#missing"></a><a href="https://example.invalid/#missing"></a><a href="mailto:x@example.invalid"></a>');
is($r->{statistics}{reference_count}, 0, 'other-document references not checked');
is($r->{statistics}{out_of_scope_href_count}, 3, 'out-of-scope count');
$r = audit_html("<a href=\" \t#in\r\ntro \"></a><h2 id=\"intro\"></h2>");
is_deeply(codes($r), [], 'URL tabs, newlines and edge whitespace handled');
$r = audit_html('<map><area href="#map"></map><h2 id="map"></h2>');
is_deeply(codes($r), [], 'area link checked');
$r = audit_html('<A HREF=#x></A><H2 ID=x></H2>');
is_deeply(codes($r), [], 'HTML case and unquoted attributes');

my $located = "أ😀\r\nنص<a href=\"#gone\"></a>\r<h2 id=\"x\"></h2>\n";
$r = audit_html($located);
is($r->{issues}[0]{line}, 2, 'CRLF location line');
is($r->{issues}[0]{column}, 3, 'Unicode character column after Arabic');
is($r->{issues}[0]{byte_column}, 5, 'UTF-8 byte column differs');
is($r->{issues}[0]{byte_offset}, 12, 'absolute byte offset includes preceding emoji');
is($r->{targets}[0]{line}, 3, 'bare CR starts a line');
is_deeply(audit_utf8(encode('UTF-8', $located)), $r, 'byte and character APIs agree');
$r = audit_utf8("\xEF\xBB\xBF<a href=\"#gone\"></a>");
is($r->{issues}[0]{byte_offset}, 3, 'BOM retained in byte accounting');
is($r->{issues}[0]{column}, 2, 'BOM retained in character accounting');

for my $case ([undef], [[],], ['x', 'unknown', 1], ['x', 'max_issues', 0], ['x', 'max_bytes', -1], ['x', 'max_bytes']) {
    my $ok = eval { audit_html(@$case); 1 };
    ok(!$ok && length($@), 'bad API argument raises an exception');
}
ok(!eval { audit_utf8("\xFF"); 1 }, 'invalid input UTF-8 rejected');
ok(!eval { audit_html('أ', max_bytes => 1); 1 }, 'size limit measured in UTF-8 bytes');
$r = audit_html('<a href="#a"></a><a href="#b"></a><a href="#c"></a>', max_issues => 2);
is($r->{statistics}{issue_count}, 3, 'total count remains complete when capped');
is($r->{statistics}{reported_issue_count}, 2, 'reported count capped');
is($r->{statistics}{truncated}, 1, 'truncation explicit');
is($r->{statistics}{reference_count}, 3, 'references remain complete');
is_deeply(codes(audit_html('')), [], 'empty input is clean');

my $many = join '', map { qq{<a href="#s$_"></a><h2 id="s$_"></h2>} } 1 .. 5000;
$r = audit_html($many);
is($r->{statistics}{reference_count}, 5000, 'many references counted');
is_deeply(codes($r), [], 'many matching references remain clean');
my $duplicates = ('<h2 id="same"></h2>' x 50) . '<a href="#same"></a>';
$r = audit_html($duplicates);
is($r->{references}[0]{target_count}, 50, 'full ambiguous target count');
is(scalar @{ $r->{references}[0]{targets} }, 10, 'related reference locations are bounded');
is($r->{statistics}{target_count}, 50, 'global targets remain complete');
is($r->{issues}[-1]{related_count}, 50, 'issue keeps full related count');
done_testing;
