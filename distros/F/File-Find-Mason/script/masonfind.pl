#!/usr/bin/perl

use strict;
use warnings;
use File::Find::Mason;
use Getopt::Long;

sub Help {
	print STDERR "Usage:  $0 [--help] [--verbose] [--] file...\n";
}

my %opt=(
	verbose =>0,
	help    =>0,
);

GetOptions(
	'verbose'=>\$opt{verbose},
	'help'   =>\$opt{help},
);
if($opt{help}||!@ARGV) { exit(Help()) }

foreach my $target (@ARGV) {
	my @found=File::Find::Mason::find({wanted=>undef,verbose=>$opt{verbose}},$target);
	if(@found) { print join("\n",@found,"") }
}

__END__

=head1 NAME

masonfind.pl - a tool to quickly find Mason files

=head1 SYNOPSIS

	masonfind.pl [--verbose] file1 dir2 ...

=cut
