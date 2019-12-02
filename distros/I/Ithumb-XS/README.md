# Ithumb::XS

Ithumb::XS - is a fast, small (one function) and simple Perl-XS module
for creation a thumbnails, using Imlib2 library.

## Installation

To manual install this module type the following:

```
$ perl Makefile.PL
$ make
$ make test
$ make install
```

To automatical install this module type the following:

```
$ cpan -i Ithumb::XS
```

## Dependences

This module requires these other modules and libraries:

  Imlib2 (binary and headers)

## Usage

```perl
use Ithumb::XS ();

Ithumb::XS::convert_image({
    width     => 800,
    height    => 600,
    src_image => 'src_image.jpg',
    dst_image => 'dst_image.jpg'
});
```

OO-interface:

```perl
use Ithumb::XS;

my $ithumb = Ithumb::XS->new;
$ithumb->convert({
    width     => 800,
    height    => 600,
    src_image => 'src_image.jpg',
    dst_image => 'dst_result_image.jpg'
});
```

## CopyRight and license

Copyright (C) 2018, 2019 by Peter P. Neuromantic <p.brovchenko@protonmail.com>.

For more information see LICENSE file.
