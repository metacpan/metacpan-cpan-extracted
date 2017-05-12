use lib 't';
use HTC_Utils qw($tdir &cdir &create_cache &remove_cache);
my $cache_dir = "cache14";
$cache_dir = create_cache($cache_dir);
use Test::More tests => 6;
use Data::Dumper;
use File::Spec;
use strict;
use warnings;
local $Data::Dumper::Indent = 1; local $Data::Dumper::Sortkeys = 1;
BEGIN { use_ok('HTML::Template::Compiled') };

eval { require Digest::MD5 };
my $md5 = $@ ? 0 : 1;
eval { require URI::Escape };
my $uri = $@ ? 0 : 1;
my $hash = {
	URITEST => 'a b c & d',
};
SKIP: {
	skip "no Digest::MD5", 2 unless $md5;
	skip "no URI::Escape", 2 unless $uri;
	my $text = qq{<TMPL_VAR .URITEST ESCAPE=URL>\n};
	my $htc = HTML::Template::Compiled->new(
		scalarref => \$text,
		file_cache_dir => $cache_dir,
        file_cache => 1,
	);
	ok($htc, "scalarref template");
	$htc->param(%$hash);
	my $out = $htc->output;
	ok($out eq 'a%20b%20c%20%26%20d'.$/, "scalarref output");
}
SKIP: {
	skip "no URI::Escape", 2 unless $uri;
	my $text = [qq(<TMPL_VAR .URITEST),qq( ESCAPE=URL >\n)];
	my $htc = HTML::Template::Compiled->new(
		arrayref => $text,
		file_cache_dir => $cache_dir,
        file_cache => 1,
	);
	ok($htc, "arrayref template");
	$htc->param(%$hash);
	my $out = $htc->output;
	ok($out eq 'a%20b%20c%20%26%20d'.$/, "arrayref output");
}

eval { require Encode };
my $encode = $@ ? 0 : 1;
SKIP: {
    skip "no Encode.pm installed", 1 unless $encode;
    skip "bug in prove on *BSD", 1 if $] =~ /^5\.010/ and $^O =~ /^(free|open)bsd$/;

    #use Devel::Peek;
    my $string = "\x{263A} <%= foo %>";
    #Dump $string;
    my $htc = HTML::Template::Compiled->new(
        scalarref => \$string,
    );
    $htc->param(foo => "\x{263A}");
    my $out = $htc->output;
    binmode STDOUT, ':encoding(utf-8)';
    binmode STDERR, ':encoding(utf-8)';
    #Dump $out;
    #print $out, $/;
    cmp_ok($out, 'eq', "\x{263A} \x{263A}", "scalarref with utf8");
}
HTML::Template::Compiled->clear_filecache($cache_dir);
remove_cache($cache_dir);
