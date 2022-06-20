#!/usr/bin/env perl
package Test::Cool::coffee;
use Getopt::App;
run(qw(h v|version dummy), sub { shift; print join('/', __FILE__, @_), "\n"; return 12 });
