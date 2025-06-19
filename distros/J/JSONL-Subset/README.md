# JSONL::Subset

A Perl module to extract a percentage of lines from a JSONL file. Useful for sampling large datasets.

## Installation

```
perl Makefile.PL
make
make test
make install
```

## Usage

```perl
use JSONL::Subset qw(subset_jsonl);

subset_jsonl(
    infile    => "data.jsonl",
    outfile   => "subset.jsonl",
    percent   => 10,
    mode      => "random", # or "start", "end"
    seed      => 42,
    streaming => 1
);
```

Or from the command line:

```
jsonl-subset --in data.jsonl --out sample.jsonl --percent 5 --mode random --seed 42 --streaming
```

## Options

### infile

Path to the file you want to import from.

### outfile

Path to where you want to save the export.

### percent

Percentage of lines to retain. Must specify percent XOR lines.

### lines

Number of lines to retain. Must specify lines XOR percent.

### mode

- random returns random lines
- start returns lines from the start
- end returns lines from the end

### seed

Only used with random, for reproducability. (optional)

### streaming

If set, infile will be streamed line by line. This makes the process take less RAM, but more wall time.

Recommended for large JSONL files.
