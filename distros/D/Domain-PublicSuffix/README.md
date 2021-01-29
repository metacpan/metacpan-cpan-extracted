# Domain-PublicSuffix
===================

A perl module to parse a domain down to the root TLD utilizing the Mozilla
PublicSuffix file.

This module utilizes the "effective_tld_names.dat" provided by Mozilla as a way
to effectively reduce a fully qualified domain name down to the absolute root.
The Mozilla PublicSuffix file is an open source, fully documented format that
shows absolute root TLDs, primarily for Mozilla's browser products to be able
to determine how far a cookie's security boundaries go.

## INSTALLATION

To install this module from Git, you will need Dist::Zilla. Once installed, run:
```
   dzil authordeps | cpanm
   dzil install
```

To install this module from an archive, type the following:
```
   perl Makefile.PL
   make
   make test
   make install
```
   OR
```
   cpanm .
```

## DEPENDENCIES

This module requires these other modules and libraries:

* Class::Accessor::Fast
* File::Spec
* Net::IDN::Encode
* Test::More

## COPYRIGHT AND LICENSE

Copyright (C) 2008-2021 by Nick Melnick

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl 5 itself.
