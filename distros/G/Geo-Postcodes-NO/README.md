# Geo-Postcodes-NO

Self-contained UTF-8 reimplementation of the historical Perl
`Geo::Postcodes::NO` module.

The public API follows the old module: procedural lookups, postcode objects,
field selection, and Norwegian type descriptions. The old dependency on the
separate `Geo::Postcodes` distribution is folded into `Geo::Postcodes::NO`.

## Data

The module reads a local copy of Bring's postcode table directly:

`lib/Geo/Postcodes/NO/postnummerregister-ansi.txt`

The source file is downloaded from:

<https://www.bring.no/postnummerregister-ansi.txt>

Bring refreshes the table once a year (the bundled copy is valid from
2026-10-01), adds new postcodes from time to time, and may adjust the
municipalities when they change (typically on 1 January).

Bring publishes the file as ANSI/Windows-1252. The module decodes it at runtime,
so returned strings are normal Perl Unicode strings. If Bring changes the
encoding, set `GEO_POSTCODES_NO_ENCODING` before loading the module.

To use your own updated file without changing the installed module, download
Bring's file yourself and validate it with the wrapper:

```sh
script/check-postcodes-no /var/lib/postnummerregister-ansi.txt
```

The wrapper sets `GEO_POSTCODES_NO_DATA` to the file argument and runs the Perl
validator in `Geo::Postcodes::NO::Check`. The validator uses
`GEO_POSTCODES_NO_ENCODING`, defaulting to `cp1252`, and checks decoding, five
tab-separated fields, valid postcode and municipality numbers, known county
prefixes, valid Bring category, duplicate postcodes, conflicting municipality
names, required names, and that `Geo::Postcodes::NO` can load the same file with
the same encoding.

`data_valid_from()` returns the bundled file's validity date. When
`GEO_POSTCODES_NO_DATA` is set, it returns `undef` because the module cannot know
the validity date of a user-supplied file.

Use the same environment variable before loading `Geo::Postcodes::NO` in your
application:

```sh
GEO_POSTCODES_NO_DATA=/var/lib/postnummerregister-ansi.txt perl app.pl

# If the file is UTF-8 instead of Bring's current cp1252/ANSI format:
GEO_POSTCODES_NO_DATA=/var/lib/postnummerregister.txt \
GEO_POSTCODES_NO_ENCODING=UTF-8 \
perl app.pl
```

## Usage

```perl
use utf8;
use feature 'say';
use Geo::Postcodes::NO;

my $p = Geo::Postcodes::NO->new('1178') or die "Unknown postcode";

say $p->location;        # OSLO
say $p->borough_number;  # 0301
say $p->borough;         # OSLO
say $p->county;          # OSLO
say $p->type;            # ST
say $p->type_verbose;    # Gateadresse
```

```perl
my @postcodes = Geo::Postcodes::NO::selection(
    county   => 'AKERSHUS',
    borough  => 'BÆRUM',
);
```

## Selection Modes

Selection values are regular expressions, and `%` is expanded to `.*`. Invalid
regular expressions return no selection. Binary modes combine the current result
set `A` with the next criterion `B`.

Supported modes: `and`, `and not`, `nand`, `nand not`, `oldnand`, `oldnand not`,
`or`, `or not`, `nor`, `nor not`, `xor`, `xor not`, `xnor`, and `xnor not`.
Initial modes `all`, `none`, `not`, and `one` are also supported.

`nand` is mathematical NAND: it returns everything except values that are in both
`A` and `B`. `nand not` applies NAND after negating `B`. The old
`Geo::Postcodes` implementation accidentally treated `nand` as part of the
`and` family; that compatibility behaviour is available as `oldnand` and
`oldnand not`.

## Documentation

Two POD documents are installed with the module:

- `Geo::Postcodes::NO::Tutorial` - a step-by-step tutorial on using the module.
- `Geo::Postcodes::NO::Selection` - the selection procedure and method in detail.

Read them with:

```sh
perldoc Geo::Postcodes::NO::Tutorial
perldoc Geo::Postcodes::NO::Selection
```

## Install and Test

```sh
perl Makefile.PL
make test
make install
```

Author-only POD checks live under `xt/`:

```sh
AUTHOR_TESTING=1 prove -l xt
```

## Release Checklist

Before release:

- Check that bundled postcode data is current and update `data_valid_from()` if needed.
- Run `script/check-postcodes-no lib/Geo/Postcodes/NO/postnummerregister-ansi.txt`.
- Run `prove -l` and `AUTHOR_TESTING=1 prove -l xt`.
- Run `perl Makefile.PL`, `make test`, and `make disttest`.
- Confirm `Changes`, `README.md`, `MANIFEST`, and repository metadata are up to date.

## Author

Arne Sommer <perl@bbop.org>

## Acknowledgments

The 1.00 rewrite was developed with the assistance of the Qwen 3.8 27B large
language model.

## License

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
