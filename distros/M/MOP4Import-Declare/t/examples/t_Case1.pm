#!/usr/bin/env perl
package
  t_Case1;
use MOP4Import::Base::CLI_JSON -as_base
  , [fields => qw(foo)]
  ;

sub cmd_foo : Doc(this is foo command) { print "FOO\n"; }

sub onconfigure_bar :Doc(bar option) :ZshCompleter(:filename:_files) {
  (my MY $self, my $value) = @_;
}

MY->cli_run(\@ARGV) unless caller;
1;
