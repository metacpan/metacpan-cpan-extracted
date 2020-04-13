Domain-PublicSuffix
===================

A perl module to parse a domain down to the root TLD utilizing the Mozilla
PublicSuffix file.

INSTALLATION
------------

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

DEPENDENCIES
------------

This module requires these other modules and libraries:

  Class::Accessor::Fast
  File::Spec
  Net::IDN::Encode
  Test::More

COPYRIGHT AND LICENSE
---------------------

Copyright (C) 2008-2020 by Nicholas Melnick

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.
