#! /usr/bin/env perl
use strict;
use warnings;
use Benchmark ':all';
$|= 1;

sub run_exporter {
	system($^X, "benchmark.pl", @_) == 0
		or die "Failed while running benchmark.pl ".join(' ', @_)."\n";
}

for ([200,2,4,8], [200,5,4,20], [100,2,10,30], [100,5,10,30], [50,10,50,20], [10,50,50,200]) {
	my ($loop, $export_mods, $exports, $packages)= @$_;
	print "\nCreating $export_mods modules, each exporting $exports symbols, imported into each of $packages packages\n";
	print "$loop iterations (invocations of perl interpreter)\n";
	cmpthese($loop, {
		'Exporter'             => "run_exporter('Exporter',$export_mods,$exports,$packages)",
		'Exporter::Tiny'       => "run_exporter('Exporter::Tiny',$export_mods,$exports,$packages)",
		'Sub::Exporter'        => "run_exporter('Sub::Exporter',$export_mods,$exports,$packages)",
		'Exporter::Extensible' => "run_exporter('Exporter::Extensible',$export_mods,$exports,$packages)",
		'Exporter::Extensible-cwd' => "run_exporter('Exporter::Extensible-cwd',$export_mods,$exports,$packages)",
	});
}	
