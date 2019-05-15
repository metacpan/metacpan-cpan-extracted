# FASTX::Reader
[![CPAN](https://img.shields.io/badge/CPAN-FASTX::Reader-1abc9c.svg)](https://metacpan.org/pod/FASTX::Reader)
[![Kwalitee](https://cpants.cpanauthors.org/release/PROCH/FASTX-Reader-0.05.svg)](https://cpants.cpanauthors.org/release/PROCH/FASTX-Reader-0.05)
[![Version](https://img.shields.io/cpan/v/Proch-N50.svg)](https://metacpan.org/pod/FASTX::Reader)
[![Tests](https://img.shields.io/badge/Tests-Grid-1abc9c.svg)](https://www.cpantesters.org/distro/F/FASTX-Reader.html)
[![Travis Build Status](https://travis-ci.org/telatin/FASTQ-Parser.svg?branch=master)](https://travis-ci.org/telatin/FASTQ-Parser)

### An OOP Perl module to parse FASTA and FASTQ files

This is a package built using Heng Li's _readfq()_ subroutine ([link](https://github.com/lh3/readfq)).

For updated documentation, please visit *[Meta::CPAN](https://metacpan.org/pod/FASTX::Reader)*.

### Installation

With _CPAN minus_:
```
cpanm FASTX::Reader
```

If you don't have _CPAN minus_, you can install it with:
```
cpan App::cpanminus
```

### Short synopsis

```perl
use FASTX::Reader;
my $filepath = '/path/to/assembly.fastq';
die "Input file not found: $filepath\n" unless (-e "$filepath");
my $fasta_reader = FASTX::Reader->new({ filename => "$filepath" });
 
while (my $seq = $fasta_reader->getRead() ) {
  print $seq->{name}, "\t", $seq->{seq}, "\t", $seq->{qual}, "\n";
}
```

### Contributors
- Andrea Telatin
- Fabrizio Levorin
