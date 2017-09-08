#!/usr/bin/env perl

use Test::Most tests => 1;

use Chart::Clicker;
use Devel::IPerl::Plugin::ChartClicker;
use IPerl;

IPerl->load_plugin($_) for qw(ChartClicker CoreDisplay);

subtest "ChartClicker data" => sub {
	my %formats_mime = (
		'svg' => 'image/svg+xml',
		'png' => 'image/png',
	);

	plan tests => scalar keys %formats_mime;

	while( my ($format, $mime) = each %formats_mime ) {
		my $cc = Chart::Clicker->new( format => $format );
		my @values = (42, 25, 86, 23, 2, 19, 103, 12, 54, 9);
		$cc->add_data('Sales', \@values);

		my $rep = $cc->iperl_data_representations;
		ok( exists $rep->{ $mime }, "Has $format representation as $mime" );
	}
};

done_testing;
