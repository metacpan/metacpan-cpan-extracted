#!/usr/bin/perl -w

use strict;

use Language::Homespring;
use Language::Homespring::Visualise::GraphViz;

my $filename = $ARGV[0];
die "please specify a file to read!\n" unless $filename;

open(F, $filename) or die "couldn't read file $filename: $!";
my $code = join '', <F>;
close(F);

my $hs = new Language::Homespring();
$hs->parse($code);

my $vs = new Language::Homespring::Visualise::GraphViz({
		'interp' => $hs,
		'spring_col' => '#ffcccc',
		'node_col' => '#ccffcc',
		'fontname' => 'Arial',
		'fontsize' => 10,
	});
print $vs->do()->as_gif;
