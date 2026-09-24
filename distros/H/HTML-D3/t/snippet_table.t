#!/usr/bin/env perl

use warnings;
use strict;

use Test::Most tests => 28;
use_ok('HTML::D3');

my $chart = HTML::D3->new(
	width  => 800,
	height => 600,
	title  => 'Table Test',
);

my @data = (
	['Name', 'Value', 'Category'],
	['Alpha',  300,  'A'],
	['Beta',   150,  'B'],
	['Gamma',  450,  'C'],
);

isa_ok($chart, 'HTML::D3', 'chart object created');

# ── Basic return shape ────────────────────────────────────────────────────────
my $fragment;
lives_ok { $fragment = $chart->render_table_snippet(\@data) } 'Renders without error';
is(ref($fragment), 'HASH', 'Returns a hash reference');
is($fragment->{table_id}, 'data_table', 'table_id is "data_table" (not svg_id)');
ok(!exists($fragment->{svg_id}), 'No svg_id key in return hashref');

my $html = $fragment->{html};
like($html, qr/<table id="data_table"/, 'Table element has id="data_table"');
like($html, qr/<th[^>]*>Name<\/th>/,    'Header "Name" present');
like($html, qr/<th[^>]*>Value<\/th>/,   'Header "Value" present');
like($html, qr/<td>Alpha<\/td>/,        'Row data "Alpha" present');
like($html, qr/<td>450<\/td>/,          'Row data 450 present');
unlike($html, qr/<!DOCTYPE/i,           'No DOCTYPE (snippet)');
unlike($html, qr/<html/i,               'No <html> wrapper');
unlike($html, qr/<head/i,               'No <head> element');
unlike($html, qr/<body/i,               'No <body> element');
ok(utf8::is_utf8($html) || $html !~ /[^\x00-\x7f]/, 'Returns Perl character string');

# ── Sortable (default on) ─────────────────────────────────────────────────────
like($html, qr/dt-sortable/, 'sortable: dt-sortable class present by default');
like($html, qr/d3\.select/,  'sortable: D3 select used in script');

# ── sortable => 0 ────────────────────────────────────────────────────────────
my $nosort_html = $chart->render_table_snippet(\@data, { sortable => 0 })->{html};
unlike($nosort_html, qr/dt-sortable/, 'sortable => 0: dt-sortable class absent');

# ── caption ───────────────────────────────────────────────────────────────────
my $cap_html = $chart->render_table_snippet(\@data, { caption => 'My Report' })->{html};
like($cap_html, qr/<caption>My Report<\/caption>/, 'Caption text present');

# ── id opt ────────────────────────────────────────────────────────────────────
my $id_frag = $chart->render_table_snippet(\@data, { id => 'custom_tbl' });
is($id_frag->{table_id}, 'custom_tbl', 'Custom table_id returned');
like($id_frag->{html}, qr/<table id="custom_tbl"/, 'Custom id in table element');

# ── XSS in headers/cells escaped ─────────────────────────────────────────────
my $xss_html = $chart->render_table_snippet([
	['Col<script>', 'Val'],
	['<b>A</b>',    '&amp;'],
])->{html};
like($xss_html, qr/Col&lt;script&gt;/, 'XSS: header escaped');
like($xss_html, qr/&lt;b&gt;A&lt;\/b&gt;/, 'XSS: cell escaped');

# ── error conditions ──────────────────────────────────────────────────────────
throws_ok { $chart->render_table_snippet('not an array') }
    qr/Data must be an array of arrays/, 'Non-arrayref data dies';

throws_ok { $chart->render_table_snippet([]) }
    qr/Data must have at least one row/, 'Empty data dies';

throws_ok { $chart->render_table_snippet(['not_a_row']) }
    qr/Each row must be an array reference/, 'Non-arrayref header dies';

throws_ok { $chart->render_table_snippet([['H1', 'H2'], 'not_a_row']) }
    qr/Each row must be an array reference/, 'Non-arrayref data row dies';
