#!/usr/bin/env bash

cover -delete
HARNESS_PERL_SWITCHES=-MDevel::Cover make test
cover

(
cd cover_db || exit
open coverage.html
)


