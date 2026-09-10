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

## License

This software is licensed under the GPLv3 license. See the LICENSE file for details.

## Copyright

Copyright 2017-2026 Koha Development Team
