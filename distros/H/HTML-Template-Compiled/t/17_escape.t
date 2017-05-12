# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl HTML-Template-Compiled.t'

use Test::More tests => 6;
use Data::Dumper;
use File::Spec;
use strict;
use warnings;
local $Data::Dumper::Indent = 1; local $Data::Dumper::Sortkeys = 1;
BEGIN { use_ok('HTML::Template::Compiled') };
BEGIN { use_ok('HTML::Template::Compiled::Plugin::XMLEscape') };
my $cache = File::Spec->catfile('t', 'cache');

{

	my $htc = HTML::Template::Compiled->new(
		scalarref => \<<'EOM',
<tmpl_var html>
<tmpl_var nohtml ESCAPE=0>
EOM
		default_escape => 'HTML',
		debug => 0,
	);
	my $html = '<html>';
	my $nohtml = $html;
	$htc->param(
		html => $html,
		nohtml => $nohtml,
	);
    $html = HTML::Template::Compiled::Utils::escape_html($html);
	my $out = $htc->output;
	$out =~ tr/\n\r //d;
	#print $out,$/;
	cmp_ok($out, "eq", $html . $nohtml, "default_escape");
}

{

    my $htc = HTML::Template::Compiled->new(
        scalarref => \<<"EOM",
<script>
var test = '<%= foo escape=JS %>';
</script>
EOM
        debug => 0,
    );
    my $foo = "test \\'foo";
    $htc->param(foo => $foo);
    my $out = $htc->output;
    $out =~ tr/\n\r//d;
    $out =~ s/^\s*//;
    #print $out, $/;
    cmp_ok($out, 'eq', q{<script>var test = 'test \\\\\\'foo';</script>}, "escape=JS");
}
{

    my $htc = HTML::Template::Compiled->new(
        scalarref => \<<"EOM",
        <xml foo="<%= foo escape=xml_attr %>"><%= foo escape=xml %></xml>
EOM
        plugin => [qw(::XMLEscape)],
        debug => 0,
    );
    #warn Data::Dumper->Dump([\$htc], ['htc']);
    my $foo = "<to_escape>";
    my $xml = HTML::Template::Compiled::Plugin::XMLEscape::escape_xml($foo);
    my $xml_attr = HTML::Template::Compiled::Plugin::XMLEscape::escape_xml_attr($foo);
    $htc->param(foo => $foo);
    my $out = $htc->output;
	$out =~ tr/\n\r//d;
    $out =~ s/^\s*//;
    #print $out, $/;
    cmp_ok($out, 'eq', qq{<xml foo="$xml_attr">$xml</xml>}, "Plugin XMLEscape");
}

{

    my $htc = HTML::Template::Compiled->new(
        scalarref => \<<"EOM",
        <%= foo escape=ijson %>
EOM
        debug => 0,
    );
    my $foo = q#{ "a" : "name='myvar'" }#;
    my $ijson = HTML::Template::Compiled::Utils::escape_ijson($foo);
    $htc->param(foo => $foo);
    my $out = $htc->output;
    $out =~ tr/\n\r//d;
    $out =~ s/^\s*//;
    #print $out, $/;
    cmp_ok($out, 'eq', qq{$ijson}, "ijson escape");
}

