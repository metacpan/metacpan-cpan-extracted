#!/usr/bin/env perl

use 5.018;
use FindBin qw($Bin);
use Getopt::Long;
use Term::ANSIColor;
say $Bin;

my $opt_longoutput = undef;
my $opt_input = "$Bin/test.fasta";
say STDERR color('green'),
" TEST FASTA/FASTQ PARSER
 -i, --inputfile  FILE     (default: $opt_input)
 -l, --longoutput          Will print all sequence names
", color('reset');


my $optparser = GetOptions (
	"i|inputfile=s" => \$opt_input,    # numeric
	"l|longoutput"  => \$opt_longoutput,
);
# @aux is a buffer array required by &readfq
my @aux = undef;

my $total_seqs = 0;
my $longest_size = 0;

open I, '<', "$opt_input" || die "FATAL ERROR:\nUnable to find input file <$opt_input>.\n";


while (my ($name, $seq, $qual) = readfq(\*I, \@aux)) {
	$total_seqs++;
	$longest_size = length($seq) if (length($seq) > $longest_size);
	if ($opt_longoutput) {
		say "[SeqNo. $total_seqs]\t$name\t", substr($seq, 0, 10), "...";
	}
}

say "Total seqs:\t$total_seqs\nLongest seq:\t$longest_size bp";

sub readfq {
    my ($fh, $aux) = @_;
    @$aux = [undef, 0] if (!(@$aux));	# remove deprecated 'defined'
    return if ($aux->[1]);
    if (!defined($aux->[0])) {
        while (<$fh>) {
            chomp;
            if (substr($_, 0, 1) eq '>' || substr($_, 0, 1) eq '@') {
                $aux->[0] = $_;
                last;
            }
        }
        if (!defined($aux->[0])) {
            $aux->[1] = 1;
            return;
        }
    }
    my $name = /^.(\S+)/? $1 : '';
    my $comm = /^.\S+\s+(.*)/? $1 : ''; # retain "comment"
    my $seq = '';
    my $c;
    $aux->[0] = undef;
    while (<$fh>) {
        chomp;
        $c = substr($_, 0, 1);
        last if ($c eq '>' || $c eq '@' || $c eq '+');
        $seq .= $_;
    }
    $aux->[0] = $_;
    $aux->[1] = 1 if (!defined($aux->[0]));
    return ($name, $seq) if ($c ne '+');
    my $qual = '';
    while (<$fh>) {
        chomp;
        $qual .= $_;
        if (length($qual) >= length($seq)) {
            $aux->[0] = undef;
            return ($name, $seq, $comm, $qual);
        }
    }
    $aux->[1] = 1;
    return ($name, $seq, $comm);
}

