#!/usr/bin/perl -w

use strict;
use lib 'lib';

use MARC::Fast;
use Getopt::Std;
use Data::Dump qw/dump/;

=head1 NAME

dump_fastmarc.pl - display MARC records

=head2 USAGE

  dump_fastmarc.pl /path/to/dump.marc

=head2 OPTIONS

=over 16

=item -o offset

dump records starting with C<offset>

=item -l limit

dump just C<limit> records

=item -h

dump result of C<to_hash> on record

=item -d

turn debugging output on

=item -t

dump tsv file for TokyoCabinet import

=back

=cut

my %opt;
getopts('do:l:ht', \%opt);

my $file = shift @ARGV || die "usage: $0 [-o offset] [-l limit] [-h] [-d] file.marc\n";

my $marc = new MARC::Fast(
	marcdb => $file,
	debug => $opt{d},
);


my $min = 1;
my $max = $marc->count;

if (my $mfn = $opt{n}) {
	$min = $max = $mfn;
	print STDERR "Dumping $mfn only\n";
} elsif (my $limit = $opt{l}) {
	print STDERR "$file has $max records, using first $limit\n";
	$max = $limit;
} else {
	print STDERR "$file has $max records...\n";
}

for my $mfn ($min .. $max) {
	my $rec = $marc->fetch($mfn) || next;
	warn "rec is ",dump($rec) if ($opt{d});
	if ( $opt{t} ) {
		print "rec\t$mfn\tleader\t", $marc->last_leader, "\t";
		my $ascii = $marc->to_ascii($mfn);
		$ascii =~ s{\n}{\t}gs;
		print "$ascii\n";
	} else {
		print "REC $mfn\n";
		print $marc->last_leader,"\n";
		print $marc->to_ascii($mfn),"\n";
	}
	warn "hash is ",dump($marc->to_hash($mfn, include_subfields => 1)) if ($opt{h});
}
