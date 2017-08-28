Contributing
============

Welcome, so you are thinking about contributing ?
Awesome, this a great place to start.

Setup
-----

```bash
$ git clone EPFL_SCIPER_LIST_REPO
$ cd epfl-sciper-list
$ perl Build.PL
$ perl Build installdeps
```

Test
----

Unit and integration tests:

```bash
$ perl Build test
```

Code coverage:

```bash
$ perl Build testcover
```

Run
---

```bash
$ perl -Ilib bin/epfl-sciper-list.pl
```

Package
-------

```bash
$ perl Build dist
```

Release
-------

  1. Bump the correct version.
  2. Update the file [Changes](Changes)
  3. Package the module.
  4. Upload the package to https://pause.perl.org/
  5. Create the tag (``git tag -a v<version> -m "Tagging the v<version> release"``) 

License
-------

Apache License 2.0

(c) ECOLE POLYTECHNIQUE FEDERALE DE LAUSANNE, Switzerland, VPSI, 2017.

See the [LICENSE](LICENSE) file for more details.
