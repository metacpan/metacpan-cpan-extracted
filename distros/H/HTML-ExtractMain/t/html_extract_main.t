#!perl

use utf8;
use Test::More tests => 8;

BEGIN { use_ok( 'HTML::ExtractMain', 'extract_main_html' ); }

empty_content_tests();
simple_content();
simple_treebuilder_content();
output_types();

sub empty_content_tests
{
    local $SIG{__WARN__} = sub { };

    is( extract_main_html(),   undef, 'need defined content' );
    is( extract_main_html(''), undef, 'need non-empty content' );
}

sub simple_content
{
    is( extract_main_html('<p>Hi!</p>'), '<p>Hi!</p>', 'simple content works' );
}

sub simple_treebuilder_content
{
    require HTML::TreeBuilder;
    my $simple = '<p>Hi!</p>';
    my $tree = HTML::TreeBuilder->new_from_content($simple);
    my $got = extract_main_html($tree);
    is ($got, $simple, 'simple content as TreeBuilder');
}

sub output_types
{
    my $html = <<'END';
<!DOCTYPE html>
<html lang="de">
<head>
    <meta charset="utf-8">
    <title>Perl</title>
</head>

<body>
<div id="header">Header!</div>
<div id="nav"><a href="/">Home</a></div>
<div id="body">

<h1 class="Article&#x27;s title">Perl</h1>

<p>Perl ist eine freie, plattformunabhängige und interpretierte
Programmiersprache (Skriptsprache), die mehrere Programmierparadigmen
unterstützt.</p>

</div>
<div id="footer">Footer</div>
</body>
</html>
END

    my $r = extract_main_html($html);
    chomp $r if $r;
    is( $r,
        '<div id="body"><h1 class="Article&apos;s title">Perl</h1><p>Perl ist eine freie, plattformunabhängige und interpretierte Programmiersprache (Skriptsprache), die mehrere Programmierparadigmen unterstützt.</p></div>',
        'body extracted as XHTML' );

    $r = extract_main_html($html, output_type => 'HTML');
    chomp $r if $r;
    is( $r,
        '<div id="body"><h1 class="Article&#39;s title">Perl</h1><p>Perl ist eine freie, plattformunabh&auml;ngige und interpretierte Programmiersprache (Skriptsprache), die mehrere Programmierparadigmen unterst&uuml;tzt.</div>',
        'body extracted as HTML' );

    my $rtree = extract_main_html($html, output_type => 'tree');
    is( $rtree->starttag,
        '<div id="body">',
        'body extracted as tree' );
}

# Local Variables:
# mode: perltidy
# End:
