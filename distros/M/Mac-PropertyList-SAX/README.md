# `Mac-PropertyList-SAX`

This file describes `Mac::PropertyList::SAX`, which extends [`Mac::PropertyList`][mp],
using a "real" XML parser from `XML::SAX::ParserFactory` to speed up processing
of large files (small files may suffer a reduction in performance due to the
overhead of invoking the parser).

See the [module POD][pod] and [`Mac::PropertyList`][mp] for more information.

# Installation

To install this module, run the following commands:

    perl Makefile.PL
    make
    make test
    make install


# Copyright and licence

Copyright (C) 2006-2022 Darren M. Kulp

This program is free software under the terms of the Artistic License 2.0; see
the accompanying [`LICENSE`][lic] file for full terms.

[pod]: README.pod
[mp]: https://github.com/briandfoy/mac-propertylist
[lic]: LICENSE
