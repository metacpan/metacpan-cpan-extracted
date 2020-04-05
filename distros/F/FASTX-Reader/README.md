# FASTX::Reader
[![CPAN](https://img.shields.io/badge/CPAN-FASTX::Reader-1abc9c.svg)](https://metacpan.org/pod/FASTX::Reader)
[![Version](https://img.shields.io/cpan/v/FASTX-Reader.svg)](https://metacpan.org/pod/FASTX::Reader)
[![Tests](https://img.shields.io/badge/Tests-Grid-1abc9c.svg)](https://www.cpantesters.org/distro/F/FASTX-Reader.html)
[![Travis Build Status](https://travis-ci.org/telatin/FASTQ-Parser.svg?branch=master)](https://travis-ci.org/telatin/FASTQ-Parser)
[![Kwalitee](https://cpants.cpanauthors.org/release/PROCH/FASTX-Reader-0.05.svg)](https://cpants.cpanauthors.org/release/PROCH/FASTX-Reader-0.60)

### A Perl module to parse FASTA and FASTQ files

This is a package built using Heng Li's _readfq()_ subroutine ([link](https://github.com/lh3/readfq)). For updated documentation, please visit *[Meta::CPAN](https://metacpan.org/pod/FASTX::Reader)*.

The FASTX::Reader module also ships *fqc* (FASTQ counter), a program to quickly count the number of sequences in a set of FASTA/FASTQ files, also .gz compressed.

### Installation

With _CPAN minus_:
```
cpanm FASTX::Reader
```

If you don't have _CPAN minus_, you can install it with:
```
cpan App::cpanminus
```

### Using 'fqc'
```
fqc [options] FILE1 FILE2 ... FILEn
```

The output is simply filename/read counts, but can be expanded with: `-t` for TSV, `-c` for CSV, `-j` for JSON, `-x` to print in ASCII table.
Type `fqc --help` for [full manual](https://metacpan.org/pod/distribution/FASTX-Reader/bin/fqc).

### Using the module

```perl
use FASTX::Reader;
my $filepath = '/path/to/assembly.fastq';
die "Input file not found: $filepath\n" unless (-e "$filepath");
my $fasta_reader = FASTX::Reader->new({ filename => "$filepath" });
 
while (my $seq = $fasta_reader->getRead() ) {
  print STEDRR "Printing ", $seq->{name}, ' (', $seq->{comment}, ")\n";
  print $seq->{name}, "\t", $seq->{seq}, "\t", $seq->{qual}, "\n";
}
```

### Contributors
- Andrea Telatin
- Fabrizio Levorin
