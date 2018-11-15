Contributing
============

Welcome, so you are thinking about contributing ?
Awesome, this a great place to start.

Setup
-----

```bash
git clone git@github.com:williambelle/filmaffinity-userrating.git
cd filmaffinity-userrating
perl Build.PL
perl Build installdeps
```

Test
----

Unit and integration tests:

```bash
perl Build test
```

Code coverage:

```bash
perl Build testcover
```

Run
---

```bash
perl -Ilib bin/filmaffinity-get-rating.pl --userid=196435

perl -Ilib bin/filmaffinity-get-movie-info.pl --id=348488
```

Package
-------

```bash
perl Build dist
```

Release
-------

  1. Bump the correct version.
  2. Update the file [Changes](Changes)
  3. Package the module.
  4. Upload the package to https://pause.perl.org/
  5. Create the tag (`git tag -a v<version> -m "Tagging the v<version> release"`) 

License
-------

Copyright (C) 2013-2018 William Belle

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.