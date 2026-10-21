#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

eval 'use Test::Pod::Coverage 1.08';
plan skip_all => 'Test::Pod::Coverage 1.08 required for testing POD coverage' if $@;

# Tie::Function::Examples implements the tie interface, documented by perltie
all_pod_coverage_ok({ trustme => [qr/^(?:TIEHASH|FETCH|STORE|FIRSTKEY|NEXTKEY|EXISTS|DELETE|CLEAR)$/] });
