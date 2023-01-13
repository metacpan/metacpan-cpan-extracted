#!/usr/bin/env perl
# ABSTRACT: A demo implementation to filter fastx files by length
# PODNAME: fqlen.pl

use 5.014;
use FASTX::Reader;
use Getopt::Long;
use File::Basename;
use Pod::Usage;
my $PROGRAM = 'fqlen';
my $VERSION = '0.1';
my $DESCR   = 'Select sequences by size';
my $AUTHOR  = 'Andrea Telatin (proch)';



my %schemes = (
	'raw' => 'Do not change sequence name (default)',
	'num' => 'Numbered sequence (see also -p)',
	'file'=> 'Use file basename as prefix',
);
my $opt_minlen = 1;
my $opt_maxlen = 0;
my (
  $opt_fasta_format,
  $opt_fasta_width,
  $opt_verbose,
  $opt_prefix,
  $opt_strip_comment,
  $opt_addlength,
  $opt_help,
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
 'h|help'            => \$opt_help,
);
pod2usage({-exitval => 0, -verbose => 2}) if $opt_help;
usage() unless defined $ARGV[0];

# Check schemes
if (not defined $schemes{$opt_name}) {
	usage();
	die "Name scheme -n '$opt_name' is not valid [choose: ", join(",", keys %schemes), "]\n";
}

# Separator for read name is '' if no prefix is given
my $sep = '';
$sep = $opt_separator if ($opt_prefix);

my $global_counter = 0;
my $global_printed = 0;
my %check_reads;
foreach my $input_file (@ARGV) {
	if (! -e "$input_file") {
		verbose(qq(Skipping "$input_file": file not found));
		next;
	} elsif (-d "$input_file") {
		verbose(qq(Skipping "$input_file": is a directory));
		next;
	} 
	my $reader = FASTX::Reader->new({ filename => "$input_file" });
	my $local_counter = 0;
	my $local_printed = 0;
	while (my $s = $reader->getRead() ) {
	
		my $len = length($s->{seq});
		$global_counter++;
		$local_counter++;			
		# Length Check
		next if ($len < $opt_minlen);
		next if ($opt_maxlen > 0 and $len > $opt_maxlen);
		

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
			die "FATAL ERROR: Duplicate read name <$name> using scheme $opt_name.\nReading <$input_file>, sequence number $local_counter (total sequences $global_counter)\n";
		}

		$check_reads{$name}++;
		$global_printed++;
		$local_printed++;
		# Print
		if ($opt_fasta_format or not defined $quality) {
			# In fasta format
			print '>', $name, "\n", format_dna($sequence, $opt_fasta_width);
		} else {
			# In fastq format
			print '@', $name, "\n", $sequence, "\n+\n", $quality, "\n";
		}
	}
	if ($opt_verbose and $global_counter > 0) {
	say STDERR " [$input_file]. ", sprintf("%.2f", 100*$global_printed/$global_counter), "% sequences selected.";
	}

}

if ($opt_verbose and $global_counter > 0) {
	say STDERR " [ALL_DONE]. ", sprintf("%.2f", 100*$global_printed/$global_counter), "% sequences selected.";
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

  -m, --min INT                   Minimum length to print a sequence [default: 1]
  -x, --max INT                   Maximum length to print a sequence [default: 0 for unlimited]
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

version 1.9.0

=head1 SYNOPSIS

  fqc [options] [FILE1 FILE2 FILE3...]

=head1 DESCRIPTION

A program to filter sequences by minimum/maximum lengths.
Can process multiple files and rename the produced sequences.

=head1 PARAMETERS

=head2 FILE NAME

=over 4

=item I<-a, --abspath>

Print the absolute path of the filename (the absolute path is always the table key,
but if relative paths are supplied, they will be printed).

=item I<-m, --min INT>

Minimum length to print a sequence

=item I<-x, --max INT>

Maximum length to print a sequence

=item I<-l, --len>

Add read length as comment

=item I<-f, --fasta>

Force FASTA output (default: as INPUT)

=item I<-w, --fasta-width INT>

Paginate FASTA sequences (default: no)

=item I<-n, --namescheme>

Sequence name scheme:

=item I<-p, --prefix STR>

Use as sequence name prefix this string

=item I<-c, --strip-comment>

Remove sequence comment (default: no)

=item I<--verbose>

Add verbose feedback on % of printed reads

=back

=head1 AUTHOR

Andrea Telatin <andrea@telatin.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Andrea Telatin.

This is free software, licensed under:

  The MIT (X11) License

=cut
