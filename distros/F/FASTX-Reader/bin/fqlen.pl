#!/usr/bin/env perl
# ABSTRACT: A demo implementation to filter fastx files by length
# PODNAME: fqlen.pl

use 5.014;
use FASTX::Reader;
use Getopt::Long;
use File::Basename;

my $PROGRAM = 'fqlen';
my $VERSION = '0.1';
my $DESCR   = 'Select sequences by size';
my $AUTHOR  = 'Andrea Telatin (proch)';



my %schemes = (
	'raw' => 'Do not change sequence name (default)',
	'num' => 'Numbered sequence (see also -p)',
	'file'=> 'Use file basename as prefix',
);
my (
  $opt_minlen,
  $opt_maxlen,
  $opt_fasta_format,
  $opt_fasta_width,
  $opt_verbose,
  $opt_prefix,
  $opt_strip_comment,
  $opt_addlength,
);
my  $opt_name = 'raw';
my  $opt_separator = '.';
my $_opt = GetOptions(
 'm|min=i'           => \$opt_minlen,
 'x|max=i'           => \$opt_maxlen,
 'f|fasta'           => \$opt_fasta_format,
 'w|fasta-width=i'   => \$opt_fasta_width,
 'c|strip-comment'   => \$opt_strip_comment,
 'n|namescheme=s'    => \$opt_name,
 'v|verbose'         => \$opt_verbose,
 'l|len'             => \$opt_addlength,
 's|separator=s'     => \$opt_separator,
 'p|prefix=s'        => \$opt_prefix,
);

usage() unless defined $ARGV[0];

# Check schemes
if (not defined $schemes{$opt_name}) {
	usage();
	die "Name scheme -n '$opt_name' is not valid [choose: ", join(",", keys %schemes), "]\n";
}

# Separator for read name is '' if no prefix is given
my $sep = '';
$sep = $opt_separator if ($opt_prefix);

my $global_counter++;

my %check_reads;
foreach my $input_file (@ARGV) {
	if (! -e "$input_file") {
		verbose(qq(Skipping "$input_file": file not found));
		next;
	}
	my $reader = FASTX::Reader->new({ filename => "$input_file" });
	my $local_counter = 0;
	while (my $s = $reader->getRead() ) {
	
		my $len = length($s->{seq});
		
		# Length Check
		next if ($len < $opt_minlen);
		next if ($len > $opt_maxlen);

		$global_counter++;
		$local_counter++;	
		# Read name
		my $name;
		if ($opt_name eq 'raw') {
			$name = $s->{name};		
		} elsif ($opt_name eq 'file') {
			$name = basename($input_file) . $opt_separator . $local_counter;
		} elsif ($opt_name eq 'num') {
			$name = $opt_prefix . $sep . $global_counter;
		}
	

		# Comment
		$name  .= " " .$s->{comment} unless ($opt_strip_comment);
		# Add length
		$name  .= " length=" . $len if ($opt_addlength);
		my $sequence = $s->{seq};
		my $quality  = $s->{qual};

		if ($check_reads{$name}) {
			die "Duplicate read name <$name> using scheme $opt_name.\nReading <$input_file>, sequence number $local_counter (total sequences $global_counter)\n";
		}

		$check_reads{$name}++;

		# Print
		if ($opt_fasta_format or not defined $s->{quality}) {
			# In fasta format
			print '>', $name, "\n", format_dna($sequence, $opt_fasta_width);
		} else {
			# In fastq format
			print '@', $name, "\n", $sequence, "\n+\n", $quality, "\n";
		}
	}

}

sub format_dna {
	my ($sequence, $width) = @_;
	if (not defined $width) {
		return "$sequence\n";
	}

	my $formatted;
	my $line = $width; 
	for (my $i=0; $i<length($sequence); $i+=$line) {
		my $frag = substr($sequence, $i, $line);
		$formatted.=$frag."\n";
	}
	return $formatted;
}

sub verbose {
	return unless $opt_verbose;
	say STDERR " - $_[0]";
}

sub usage {
 print STDERR<<END;
 ------------------------------------------------------------------------------- 
  $PROGRAM - $DESCR (ver. $VERSION)
 -------------------------------------------------------------------------------
  Synopsis:
    fqlen [options] FILE1 FILE2 ... FILEn

  -m, --min INT                   Minimum length to print a sequence
  -x, --max INT                   Maximum length to print a sequence
  -l, --len                       Add read length as comment
  -f, --fasta                     Force FASTA output (default: as INPUT)
  -w, --fasta-width INT           Paginate FASTA sequences (default: no)


  -n, --namescheme                Sequence name scheme:
END
 foreach my $scheme (sort keys %schemes) {
	say "\t\t- \"$scheme\" ($schemes{$scheme})";
 }
say STDERR<<END;
  -p, --prefix STR                Use as sequence name prefix this string
  -c, --strip-comment             Remove sequence comment (default: no)
    
  FILEn                           A FASTA or FASTQ file, gzipped is ok

  Note that usage with multiple files can raise errors (eg. duplicate sequence
  name). Also, wrong formatting if mixing fasta and fastq files without 
  specifying --fasta.
 -------------------------------------------------------------------------------
END
}

__END__

=pod

=encoding UTF-8

=head1 NAME

fqlen.pl - A demo implementation to filter fastx files by length

=head1 VERSION

version 0.92

=head1 AUTHOR

Andrea Telatin <andrea@telatin.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Andrea Telatin.

This is free software, licensed under:

  The MIT (X11) License

=cut
