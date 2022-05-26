#!/usr/bin/env perl
package Test::Cool::beans;
use Getopt::App;
run(sub { shift; print join('/', __FILE__, @_), "\n"; return 11 });
