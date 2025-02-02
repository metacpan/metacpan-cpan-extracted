#!/usr/bin/env perl
package
  t_Bar;
use t_Foo -as_base,
  [fields =>
   [foo => default => "in bar"]
 ];

MY->cli_run(\@ARGV) unless caller;

1;
