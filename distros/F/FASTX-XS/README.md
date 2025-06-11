# FASTX::XS

[![Actions Status](https://github.com/quadram-institute-bioscience/fastx-xs/actions/workflows/test.yml/badge.svg)](https://github.com/quadram-institute-bioscience/fastx-xs/actions)

## NAME

FASTX::XS - Fast FASTA/FASTQ parser using kseq.h

## SYNOPSIS

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

## DESCRIPTION

FASTX::XS is a Perl module for fast parsing of FASTA and FASTQ files
using the kseq.h library from Heng Li's klib. It supports both uncompressed and
gzipped files.

This module provides a simple interface to access sequences from FASTA/FASTQ files
with high performance and low memory usage.

## METHODS

### new(filename)

Creates a new parser object for the specified file. The file can be either a regular
FASTA/FASTQ file or a gzipped file (.gz extension).

### next\_seq()

Returns the next sequence from the file as a hash reference with the following keys:

- name - The sequence identifier (required)
- seq - The sequence string (required)
- comment - The comment string (optional)
- qual - The quality string for FASTQ files (optional)

Returns undef when there are no more sequences to read.

## AUTHOR

Andrea Telatin, *proch@cpan.org*

## COPYRIGHT AND LICENSE

Copyright (C) 2025 by Quadram Institute Bioscience, Norwich, UK

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
