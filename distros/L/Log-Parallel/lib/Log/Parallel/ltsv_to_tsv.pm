
package Log::Parallel::ltsv_to_tsv;

use strict;
use warnings;
use Config::YAMLMacros::YAML;
use File::Slurp::Remote::SmartOpen;
use Getopt::Long;

sub run 
{
	die "$0: Usage [--add_source] metafile(s)" unless @ARGV;

	my $add_source;
	die unless GetOptions(
		'add_source'	=> \$add_source,
	);

	my @metafiles;

	for my $mf (@ARGV) {
		die "no such file '$mf'\n" unless -e $mf;
		my $meta = LoadFile($mf);
		push(@metafiles, $meta);
	}

	my $colcount = 0;
	my %allcols;
	my %cols;

	for my $meta (@metafiles) {
		for my $file (@{$meta->{FILES}}) {
			next unless $file->{items};
			$cols{$file} = $file->{header}{columns};
			for my $col (@{$cols{$file}}) {
				next if defined $allcols{$col};
				$allcols{$col} = $colcount++ 
			}
		}
	}

	print "BUCKET\tFILE\t" if $add_source;
	print join("\t", sort { $allcols{$a} <=> $allcols{$b} } keys %allcols) . "\n";

	for my $meta (@metafiles) {
		for my $file (@{$meta->{FILES}}) {
			my $prefix = '';
			$prefix = "$file->{bucket}\t$file->{host}:$file->{filename}\t" if $add_source;
			my $data;
			smartopen("$file->{host}:$file->{filename}", $data, "r");
			my @cols = map { $allcols{$_} } @{$cols{$file}};
			my %present = map { $_ => 1 } @{$cols{$file}};
			my @missing = map { $allcols{$_} } grep { ! defined($present{$_}) } keys %allcols;
			my @blanks = ( '' ) x @missing;
			while (<$data>) {
				chomp;
				my @d = split("\t", $_, -1);
				my @rec;
				@rec[@cols] = @d;
				@rec[@missing] = @blanks;
				print $prefix . join("\t", map { defined $_ ? $_ : '' } @rec) . "\n";
			}
		}
	}
}

__END__

=head1 NAME

ltsv_to_tsv - convert Log TSV files into regular TSV files

=head1 OPTIONS

 ltsv_to_tsv [--add_source] metdata_file(s)

 --add_source		Prepend each line with the filename and bucket 

=head1 DESCRIPTION

This program converts the bucketized variable-column tsv format files 
(L<Log::Parallel::TSV>) used
by the log processing system (L<Log::Parallel>) into regular 
Tab Separated Values (TSV) files with a column header.

=head1 LICENSE

This package may be used and redistributed under the terms of either
the Artistic 2.0 or LGPL 2.1 license.

