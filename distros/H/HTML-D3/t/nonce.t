#!/usr/bin/env perl

# nonce => '...' puts the same nonce on every <script> an object writes, from
# every renderer, so a page whose Content-Security-Policy allows scripts only by
# nonce runs the chart.  Without the option the output has no nonce at all, and
# a value that could end the attribute is refused.

use strict;
use warnings;

use Test::Most;

use HTML::D3;

my $NONCE = 'r4nd0m+/Nonce_-=';

my @pairs  = (['Alpha', 300], ['Beta', 150], ['Gamma', 450]);
my $series = [
	{ name => 'North', data => [ { label => 'Jan', value => 1000 }, { label => 'Feb', value => 1200 } ] },
	{ name => 'South', data => [ { label => 'Jan', value => 700 },  { label => 'Feb', value => 900 } ] },
];

# Each renderer with input it draws.  Snippets return { html => ... }.
my @cases = (
	[ render_bar_chart                                        => [ \@pairs ] ],
	[ render_animated_bar_chart                               => [ \@pairs ] ],
	[ render_line_chart                                       => [ \@pairs ] ],
	[ render_animated_line_chart                              => [ \@pairs ] ],
	[ render_pie_chart                                        => [ \@pairs ] ],
	[ render_animated_pie_chart                               => [ \@pairs ] ],
	[ render_line_chart_with_tooltips                         => [ \@pairs ] ],
	[ render_multi_series_line_chart_with_tooltips            => [ $series ] ],
	[ render_multi_series_line_chart_with_animated_tooltips   => [ $series ] ],
	[ render_multi_series_line_chart_with_legends             => [ $series ] ],
	[ render_multi_series_line_chart_with_interactive_legends => [ $series ] ],
	[ render_bar_chart_snippet                => [ \@pairs ] ],
	[ render_bar_chart_snippet                => [ \@pairs, { animated => 1, orientation => 'horizontal' } ] ],
	[ render_pie_chart_snippet                => [ \@pairs ] ],
	[ render_pie_chart_snippet                => [ \@pairs, { animated => 1, donut => 1 } ] ],
	[ render_line_chart_snippet               => [ \@pairs ] ],
	[ render_zoomable_line_chart_snippet      => [ \@pairs ] ],
	[ render_multi_series_line_chart_snippet  => [ $series ] ],
	[ render_scatter_chart_snippet            => [ [ [10, 20], [30, 40], [50, 15] ] ] ],
	[ render_heatmap_snippet                  => [ [ ['Jan', 'North', 100], ['Feb', 'South', 30] ] ] ],
	[ render_table_snippet                    => [ [ ['Name', 'Value'], ['Alpha', 300] ], { sortable => 1 } ] ],
	[ render_stacked_bar_snippet              => [ [ { cat => 'East', seg => 'W', val => 1 }, { cat => 'West', seg => 'G', val => 2 } ] ] ],
	[ render_combo_snippet                    => [ [ { x => 'Q1', bar_val => 1, line_val => 2 }, { x => 'Q2', bar_val => 3, line_val => 4 } ] ] ],
	[ render_treemap_snippet                  => [ [ { path => 'Root/A', value => 4 }, { path => 'Root/B', value => 2 } ] ] ],
	[ render_histogram_snippet                => [ [ 1 .. 30 ] ] ],
	[ render_histogram_snippet                => [ [ { lo => 0, hi => 10, count => 3 }, { lo => 10, hi => 20, count => 5 } ], { binned => 1 } ] ],
);

sub html_of {
	my ($out) = @_;
	return ref($out) eq 'HASH' ? $out->{html} : $out;
}

for my $case (@cases) {
	my ($method, $args) = @{$case};
	my $name = $method . (@{$args} > 1 ? ' (' . join(', ', sort keys %{ $args->[1] }) . ')' : '');

	my $with = html_of(HTML::D3->new(nonce => $NONCE)->$method(@{$args}));
	my @tags = $with =~ /(<script\b[^>]*>)/g;
	ok(scalar(@tags), "$name writes a script");
	is(scalar(grep { /\bnonce="\Q$NONCE\E"/ } @tags), scalar(@tags), "$name: every script has the nonce")
		or diag(join "\n", grep { !/nonce=/ } @tags);

	my $without = html_of(HTML::D3->new->$method(@{$args}));
	unlike($without, qr/\bnonce=/, "$name: no nonce unless asked for");
}

subtest 'the nonce is checked' => sub {
	for my $bad (q{a"b}, q{a'b}, 'a b', 'a>b', '', "a\nb") {
		throws_ok { HTML::D3->new(nonce => $bad) } qr/nonce/i, "'$bad' is refused";
	}
	lives_ok { HTML::D3->new(nonce => 'AbC123') } 'base64 is accepted';
};

subtest 'a copy keeps it' => sub {
	my $copy = HTML::D3->new(nonce => $NONCE)->new(title => 'Copy');
	like(html_of($copy->render_bar_chart_snippet(\@pairs)), qr/<script nonce="\Q$NONCE\E">/,
		'an object made from another keeps its nonce');
};

done_testing();
