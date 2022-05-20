#!/usr/bin/env perl
use Getopt::App;
run(sub { shift; print join('/', __FILE__, @_), "\n"; return 11 });
