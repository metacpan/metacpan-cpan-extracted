package FASTX::XS;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.0.4';

require XSLoader;
XSLoader::load('FASTX::XS', $VERSION);

sub new {
    my ($class, $filename) = @_;
    die "Filename required" unless defined $filename;
    die "File not found: $filename" unless -e $filename;
    
    return _xs_new($class, $filename);
}

1;

__END__

=head1 NAME

FASTX::XS - Fast FASTA/FASTQ parser using kseq.h

=head1 SYNOPSIS

  use FASTX::XS;
  
  # Parse a FASTA or FASTQ file (can be gzipped)
  my $parser = FASTX::XS->new("sequence.fa.gz");
  
  # Iterate through all sequences
  while (my $seq = $parser->next_seq()) {
      print "Name: $seq->{name}\n";
      print "Sequence: $seq->{seq}\n";
      
      # Print comment if available
      print "Comment: $seq->{comment}\n" if exists $seq->{comment};
      
      # Print quality if available (FASTQ)
      print "Quality: $seq->{qual}\n" if exists $seq->{qual};
  }

=head1 DESCRIPTION

FASTX::XS is a Perl module for fast parsing of FASTA and FASTQ files
using the kseq.h library from Heng Li's klib. It supports both uncompressed and
gzipped files.

This module provides a simple interface to access sequences from FASTA/FASTQ files
with high performance and low memory usage.

=head1 METHODS

=head2 new(filename)

Creates a new parser object for the specified file. The file can be either a regular
FASTA/FASTQ file or a gzipped file (.gz extension).

=head2 next_seq()

Returns the next sequence from the file as a hash reference with the following keys:

=over 4

=item * name - The sequence identifier (required)

=item * seq - The sequence string (required)

=item * comment - The comment string (optional)

=item * qual - The quality string for FASTQ files (optional)

=back

Returns undef when there are no more sequences to read.

=head1 AUTHOR

Andrea Telatin, E<lt>proch@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2025 by Quadram Institute Bioscience  

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
