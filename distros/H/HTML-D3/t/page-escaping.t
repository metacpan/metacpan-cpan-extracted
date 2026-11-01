#!/usr/bin/perl
# What an application hands HTML::D3 may well have come from a request or a saved
# chart, and it is written into a page.  A chart's colours and its title must not
# be able to end the script, attribute or element they are written into.

use strict;
use warnings;

use Test::Most;

use_ok('HTML::D3');

my @HOSTILE_COLOURS = (
	q{red"];alert(1);//},
	q{red';alert(1);//},
	q{</script><script>alert(1)</script>},
	qq{red\nalert(1)},
	q{red\\},
);

my @BARS   = (['a', 1], ['b', 2]);
my @POINTS = ([1, 2], [3, 4]);
my @COMBO  = ({ x => 'a', bar_val => 1, line_val => 2 });
my @HIST   = (1, 2, 3, 4);

# Each option, how to draw with it, and the colour it falls back to.
my %COLOUR_OPTIONS = (
	'bar color' => [ sub { HTML::D3->new->render_bar_chart_snippet(\@BARS, { color => $_[0] }) }, 'steelblue' ],
	'scatter color' => [ sub { HTML::D3->new->render_scatter_chart_snippet(\@POINTS, { color => $_[0] }) }, 'steelblue' ],
	'histogram color' => [ sub { HTML::D3->new->render_histogram_snippet(\@HIST, { color => $_[0] }) }, 'steelblue' ],
	'combo bar_color' => [ sub { HTML::D3->new->render_combo_snippet(\@COMBO, { bar_color => $_[0] }) }, 'steelblue' ],
	'combo line_color' => [ sub { HTML::D3->new->render_combo_snippet(\@COMBO, { line_color => $_[0] }) }, '#e15759' ],
);

subtest 'a colour cannot end what it is written into' => sub {
	for my $name (sort keys %COLOUR_OPTIONS) {
		my ($draw, $default) = @{ $COLOUR_OPTIONS{$name} };
		for my $colour (@HOSTILE_COLOURS) {
			my $html = $draw->($colour)->{html};
			unlike($html, qr/alert\(1\)/, "$name does not write out the script");
			like($html, qr/\Q$default\E/, "$name falls back to its default");
		}
	}
};

# The check is there to stop a script, so it must not stop a colour.
subtest 'every form of CSS colour is still drawn' => sub {
	for my $colour ('tomato', '#1a48c8', 'rgb(10, 20, 30)', 'rgba(10,20,30,0.5)', 'hsl(120 50% 50% / 25%)', 'var(--brand-colour)') {
		for my $name (sort keys %COLOUR_OPTIONS) {
			like($COLOUR_OPTIONS{$name}[0]->($colour)->{html}, qr/\Q$colour\E/, "$name draws $colour");
		}
	}
	like(HTML::D3->new->render_bar_chart_snippet(\@BARS, { color => 'categorical' })->{html}, qr/#4e79a7/i,
		"the 'categorical' token still means the palette");
};

# With a scheme to go to, a bad colour is as good as no colour.
subtest 'a binned histogram with a bad colour draws its scheme' => sub {
	my @bins = ({ label => '0-1', count => 1 }, { label => '1-2', count => 2 });
	my $html = HTML::D3->new->render_histogram_snippet(\@bins, {
		binned => 1, color => $HOSTILE_COLOURS[0], scheme => 'set2',
	})->{html};
	unlike($html, qr/alert\(1\)/, 'the script is not written out');
	like($html, qr/\Q${\ HTML::D3->colour_at('set2', 0) }\E/, 'the scheme is drawn instead');
};

my $TITLE = q{Tom's <b>"Q&A"</b></title><script>alert(1)</script>};
my $SHOWN = q{Tom&#39;s &lt;b&gt;&quot;Q&amp;A&quot;&lt;/b&gt;&lt;/title&gt;&lt;script&gt;alert(1)&lt;/script&gt;};

my @FULL_PAGES = (
	[ render_bar_chart => \@BARS ],
	[ render_line_chart => \@BARS ],
	[ render_animated_bar_chart => \@BARS ],
	[ render_animated_line_chart => \@BARS ],
	[ render_line_chart_with_tooltips => \@BARS ],
	[ render_pie_chart => \@BARS ],
	[ render_animated_pie_chart => \@BARS ],
	[ render_multi_series_line_chart_with_tooltips => [ { name => 's', data => \@BARS } ] ],
	[ render_multi_series_line_chart_with_animated_tooltips => [ { name => 's', data => \@BARS } ] ],
	[ render_multi_series_line_chart_with_legends => [ { name => 's', data => \@BARS } ] ],
	[ render_multi_series_line_chart_with_interactive_legends => [ { name => 's', data => \@BARS } ] ],
);

subtest 'a title is text on every full page' => sub {
	my $chart = HTML::D3->new(title => $TITLE);
	for my $case (@FULL_PAGES) {
		my ($method, $data) = @$case;
		my $html = $chart->$method($data);
		unlike($html, qr/<script>alert/, "$method does not write out the title's script");
		unlike($html, qr/<b>"Q/, "$method does not write out the title's markup");
		like($html, qr{<title>\Q$SHOWN\E</title>}, "$method: <title> holds it as text");
		like($html, qr{<h1[^>]*>\Q$SHOWN\E</h1>}, "$method: <h1> holds it as text");
	}
	is($chart->{title}, $TITLE, 'the object keeps what it was given');
};

subtest 'an ordinary title is unchanged' => sub {
	my $html = HTML::D3->new(title => 'Monthly Revenue (2026)')->render_bar_chart(\@BARS);
	like($html, qr{<title>Monthly Revenue \(2026\)</title>}, 'in <title>');
	like($html, qr{>Monthly Revenue \(2026\)</h1>}, 'in <h1>');
};

# The HTML parser looks for </script before any JavaScript is read, so nothing
# written into a script may hold it, whichever string or JSON it is inside.
my $ENDS_SCRIPT = q{</script><script>alert(1)</script>};
my $COMMENT     = q{<!--<script>};

my @LABELLED = ([$ENDS_SCRIPT, 1]);
my @NAMED_SERIES = ({ name => $ENDS_SCRIPT, data => [{ label => $ENDS_SCRIPT, value => 1 }] });

# method => [ data with the text in it, data that merely draws, options to try ]
my %SNIPPETS = (
	render_pie_chart_snippet => [ \@LABELLED, \@BARS, [qw(separator)] ],
	render_bar_chart_snippet => [ \@LABELLED, \@BARS, [qw(x_label y_label val_label)] ],
	render_line_chart_snippet => [ \@LABELLED, \@BARS, [qw(x_label y_label)] ],
	render_zoomable_line_chart_snippet => [ \@LABELLED, \@BARS, [qw(x_label y_label)] ],
	render_heatmap_snippet => [ [[$ENDS_SCRIPT, $ENDS_SCRIPT, 1]], [['a', 'b', 1]], [qw(x_label y_label val_label)] ],
	render_scatter_chart_snippet => [ [[1, 2, $ENDS_SCRIPT]], \@POINTS, [qw(x_label y_label)] ],
	render_stacked_bar_snippet => [ [{ cat => $ENDS_SCRIPT, seg => $ENDS_SCRIPT, val => 1 }], [{ cat => 'x', seg => 's', val => 1 }], [qw(x_label y_label)] ],
	render_combo_snippet => [ [{ x => $ENDS_SCRIPT, bar_val => 1, line_val => 2 }], \@COMBO, [qw(x_label bar_label line_label)] ],
	render_treemap_snippet => [ [{ path => "$ENDS_SCRIPT/b", value => 1 }], [{ path => 'a/b', value => 1 }], [qw(path_sep)] ],
	render_histogram_snippet => [ [{ label => $ENDS_SCRIPT, count => 1 }], \@HIST, [qw(x_label y_label)], { binned => 1 } ],
	render_table_snippet => [ [[$ENDS_SCRIPT], [$ENDS_SCRIPT]], [['h'], ['v']], [] ],
	render_multi_series_line_chart_snippet => [ \@NAMED_SERIES, [{ name => 'A', data => [{ label => 'x', value => 1 }] }], [qw(x_label y_label)] ],
);

subtest 'text in a snippet cannot end its script' => sub {
	for my $method (sort keys %SNIPPETS) {
		my ($with_text, $plain, $options, $data_opts) = @{ $SNIPPETS{$method} };

		my $html = HTML::D3->new->$method($with_text, $data_opts ? $data_opts : ())->{html};
		unlike($html, qr/<script>alert/, "$method: data");

		for my $option (@$options) {
			for my $text ($ENDS_SCRIPT, $COMMENT) {
				my $page = HTML::D3->new->$method($plain, { $option => $text })->{html};
				unlike($page, qr/<script>alert|<!--<script>/, "$method: $option");
			}
		}
	}
};

subtest 'text in a full page cannot end its script' => sub {
	for my $case (@FULL_PAGES) {
		my ($method, $data) = @$case;
		my $hostile = ref($data->[0]) eq 'HASH' ? \@NAMED_SERIES : \@LABELLED;
		unlike(HTML::D3->new->$method($hostile), qr/<script>alert/, "$method: data");
	}
	for my $method (qw(render_pie_chart render_animated_pie_chart)) {
		for my $separator (q{`+alert(1)+`}, q{${alert(1)}}, q{'+alert(1)+'}, $ENDS_SCRIPT) {
			my $html = HTML::D3->new->$method(\@BARS, { separator => $separator });
			unlike($html, qr/<script>alert/, "$method: separator does not end the script");
			unlike($html, qr/(?<!\\)[`'\$]\{?\+?alert/, "$method: separator <$separator> stays inside its string");
		}
	}
};

# JavaScript reads \u003c back as "<", so a chart still shows what it was given.
subtest 'the text itself survives' => sub {
	my $html = HTML::D3->new->render_bar_chart_snippet([['a<b', 1]], { x_label => 'x<y' })->{html};
	like($html, qr/a\\u003cb/, 'a data label is written with the escape');
	like($html, qr/x\\u003cy/, 'and so is an axis label');
	like(HTML::D3->new->render_pie_chart(\@BARS, { separator => ':' }), qr/ : /, 'a plain separator is unchanged');
};

subtest 'an id that could not be selected is ignored' => sub {
	for my $method (sort keys %SNIPPETS) {
		my $plain = $SNIPPETS{$method}[1];
		my $key   = $method eq 'render_table_snippet' ? 'table_id' : 'svg_id';

		my $default = HTML::D3->new->$method($plain)->{$key};
		for my $id ($ENDS_SCRIPT, q{x" onload="alert(1)}, q{a b}, q{1a}, q{a.b}) {
			my $result = HTML::D3->new->$method($plain, { id => $id });
			is($result->{$key}, $default, "$method falls back from <$id>");
			unlike($result->{html}, qr/alert\(1\)/, "$method does not write out <$id>");
		}
		for my $id (qw(chart vis-0 bi_chart_3 _x)) {
			is(HTML::D3->new->$method($plain, { id => $id })->{$key}, $id, "$method keeps <$id>");
		}
	}
};

done_testing();
