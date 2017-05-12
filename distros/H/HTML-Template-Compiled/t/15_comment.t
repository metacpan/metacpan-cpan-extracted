# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl HTML-Template-Compiled.t'

use Test::More tests => 7;
use Data::Dumper;
use File::Spec;
use strict;
use warnings;
local $Data::Dumper::Indent = 1; local $Data::Dumper::Sortkeys = 1;
BEGIN { use_ok('HTML::Template::Compiled') };
my $cache = File::Spec->catfile('t', 'cache');

{
	my $htc = HTML::Template::Compiled->new(
		scalarref => \<<'EOM',
<tmpl_if comment>
	<tmpl_var wanted>
	<tmpl_comment outer>
<tmpl_ foo
		<tmpl_comment >
			<tmpl_var unwanted>
		</tmpl_comment >
		<tmpl_var unwanted>
	</tmpl_comment outer>
<tmpl_elsif noparse>
	<tmpl_var wanted>
	<tmpl_noparse outer>
<tmpl_ foo
		<tmpl_noparse inner>
			<tmpl_var unwanted>
		</tmpl_noparse inner>
		<tmpl_var unwanted>
	</tmpl_noparse outer>
<tmpl_elsif escape>
    <tmpl_verbatim outer>
        this should be escaped: <tmpl_var test>
    </tmpl_verbatim outer>
</tmpl_if comment>
EOM
		debug => 0,
	);
	$htc->param(
		comment => 1,
		wanted => "we want this",
		unwanted => "no thanks",
	);
	my $out = $htc->output;
	#print $out,$/;
	ok(
		($out !~ m/unwanted/) &&
		$out !~ m/no thanks/ &&
		$out =~ m/we want this/,
		"tmpl_comment");
	$htc->clear_params();
	$htc->param(
		noparse => 1,
		wanted => "we want this",
		unwanted => "no thanks",
	);
	$out = $htc->output;
	#print $out,$/;
    cmp_ok($out, '=~', qr/unwanted.*unwanted/s, "tmpl_noparse 1");
    cmp_ok($out, '!~', qr/no thanks/s, "tmpl_noparse 2");
    cmp_ok($out, '=~', qr/we want this/s, "tmpl_noparse 3");
    cmp_ok($out, '=~', qr/<tmpl_ foo/s, "tmpl_noparse 4");
    my $unescaped = 'this should be escaped: <tmpl_var test>';
    {
        my $escaped = $unescaped;
        $escaped = HTML::Template::Compiled::Utils::escape_html($escaped);
        $htc->clear_params();
        $htc->param(
            escape => 1,
            wanted => "we want this",
            unwanted => "no thanks",
        );
        $out = $htc->output;
        #print $out,$/;
        like($out, qr/\Q$escaped/, "tmpl_verbatim");
    }
}
