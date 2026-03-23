#!/usr/bin/env perl

use 5.042;
no source::encoding;
use warnings FATAL => 'all';
use autodie ':default';
use DDP {output => 'STDOUT', array_max => 10, show_memsize => 1};
use Devel::Confess 'color';
#use Util qw(list_regex_files json_file_to_ref ref_to_json_file);
# s/[!@#\$\%^&*\(\)\{\}\[\]\<\>,\/'"\-\h;\+=]+/_/g; # annoying chars

sub args_or_single ($arg) {
	if ($arg =~ m/\h*,\h*[^,]/) {
		return 'args';
	} elsif ($arg =~ m/,{2,}/) {
		return 'single';
	} else {
		return 'single';
	}
}
my @arg = (
# https://matplotlib.org/stable/plot_types/basic/plot.html
'x2, y2 + 2.5, \'x\', markeredgewidth=2',
'x, y, linewidth=2.0)',
'x2, y2 - 2.5, \'o-\', linewidth=2'
);
foreach my $arg (@arg) {
	say $arg;
	say "\t" . args_or_single($arg);
}
