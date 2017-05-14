# MARCXML implementation for MARC records [![CPAN](https://img.shields.io/cpan/v/MARC-File-MARCXML.svg)](https://metacpan.org/release/MARC-File-MARCXML) [![Travis](https://img.shields.io/travis/NatLibFi/MARC-File_MARCXML.svg)](https://travis-ci.org/NatLibFi/MARC-File-MARCXML)

## Installation

To build the project run the following command ([Dist::Zilla](https://metacpan.org/pod/Dist::Zilla) must  be installed):

```sh
dzil build
```

## Testing

To run tests run the following command:

```sh
dzil test
```

## Usage

### Decoding from string to MARC::Record

```perl
use MARC::File::MARCXML;

my $record = MARC::File::MARCXML->decode($str_xml);
```

### Encoding from MARC::Record to string

```perl
use MARC::File::MARCXML;

my $str = MARC::File::MARCXML->encode($record);
```

## Copyright and licensing

Copyright (c) 2011-2014, 2016 **University Of Helsinki (The National Library Of Finland)**

This project's source code is licensed under the terms of **GNU General Public License Version 3**.
