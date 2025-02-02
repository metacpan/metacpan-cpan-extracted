#!/usr/bin/env perl
package
  t_Case04;
use MOP4Import::Base::CLI_JSON -as_base;

our @EXPORT = qw(foo bar baz);

sub foo {"FOO"}
sub bar {"BAR"}
sub baz {"BAZ"}

MY->cli_run(\@ARGV) unless caller;
1;
