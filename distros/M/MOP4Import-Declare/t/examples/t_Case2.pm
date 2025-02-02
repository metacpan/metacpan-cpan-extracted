#!/usr/bin/env perl
package
  t_Case2;

use MOP4Import::Base::CLI_JSON -as_base
  , [code_attributes => qw(Foo Bar)]
  ;

sub foo :Foo(xx) Bar(yy) {"baz"}

MY->cli_run(\@ARGV) unless caller;
1;
