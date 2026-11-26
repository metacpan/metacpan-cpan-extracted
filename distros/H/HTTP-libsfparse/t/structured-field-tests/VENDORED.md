# Vendored test suite

This directory is a copy of the HTTP Working Group's conformance test suite
for Structured Field Values:

    https://github.com/httpwg/structured-field-tests

It is included unmodified apart from the omission of files this distribution
does not use: `generate.py`, the `schema/` directory, and the
`serialisation-tests/` directory (those cases describe serialisation, which
this distribution does not do). The commit the copy was taken from is in
`UPSTREAM-COMMIT.txt`.

`README.md` is the suite's own documentation of the JSON test format.
`LICENSE.md` is the suite's license, which this copy is distributed under; it
is not the license of the rest of this distribution.

`t/13-httpwg-suite.t` runs these files. To run that test against a different
checkout of the suite instead of this copy:

    SF_TESTS_DIR=/path/to/structured-field-tests prove -b t/13-httpwg-suite.t
