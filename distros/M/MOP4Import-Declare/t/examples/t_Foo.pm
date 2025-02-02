#!/usr/bin/env perl
package
  t_Foo;
use MOP4Import::Base::CLI_JSON -as_base
  , [fields =>
     [foo => default => "base"],
   ]
  ;

MY->cli_run(\@ARGV) unless caller;
1;
