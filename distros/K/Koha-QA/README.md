# Koha::QA - Koha Quality Assurance Utilities

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

Shared QA modules for Koha and Koha plugins.

## Purpose

This repository contains reusable Perl modules for Quality Assurance checks that can be used by:

1. **Koha core** (https://git.koha-community.org/Koha-community/Koha)
2. **QA test scripts** (https://gitlab.com/koha-community/qa-test-tools)
3. **Plugin certification** (https://gitlab.com/joubu/koha-plugin-certification)

Instead of duplicating QA logic across multiple repositories, this central module provides a single source of truth.

## Tests

To run the tests:

```bash
perl Makefile.PL
make js-deps
make
make test
make clean
```

## Release

To cut a new release:

1. Verify `MANIFEST` is correct before doing anything else: build from a *fresh clone*,
   not your working tree (a working tree can have local files, like a Carton
   `cpanfile.snapshot`, that mask a `MANIFEST` referencing something git doesn't
   actually track).

   ```bash
   git clone . /tmp/koha-qa-manifest-check
   cd /tmp/koha-qa-manifest-check
   perl Makefile.PL
   ```

   `Checking if your kit is complete...` must say nothing is missing. If it does,
   the listed file either needs to be tracked in git or removed from `MANIFEST`
   (and added to `MANIFEST.SKIP`, so a later `make manifest` doesn't re-add it
   from a file that only happens to exist locally).
2. Bump `$VERSION` in `lib/Koha/QA.pm` and add an entry to `Changes`, then commit.
3. Tag the release:

   ```bash
   git tag -a vX.Y.Z -m "Release X.Y.Z"
   ```

4. Build the distribution tarball:

   ```bash
   perl Makefile.PL
   make dist
   ```

5. Push the branch and tags, then upload to CPAN:

   ```bash
   git push origin main --follow-tags
   cpan-upload Koha-QA-X.Y.Z.tar.gz
   ```

   `cpan-upload` (from `CPAN::Uploader`, `cpanm CPAN::Uploader` if missing) needs PAUSE
   credentials configured, or pass `-u YOUR_PAUSE_ID` and it will prompt for the password.

## License

This software is licensed under the GPLv3 license. See the LICENSE file for details.

## Copyright

Copyright 2017-2026 Koha Development Team
