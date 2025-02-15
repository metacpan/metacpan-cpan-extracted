#!/usr/bin/env perl
package
  t_Case1;
use MOP4Import::Base::CLI_JSON -as_base
  , [fields => qw(foo)]
  ;

# custom => builtin
sub cmd_foo : Doc(this is foo command) method { print "FOO\n"; }

# builtin => custom
sub bar : method Doc(bar) {
  "bar";
}

# custom only
sub baz : Doc(baz) {
  "baz"
}

# builtin only
sub qux : method {
  "qux"
}

sub QuuuuuuX {
  "quuuuuux"
}

sub onconfigure_bar :Doc(bar option) :ZshCompleter(:filename:_files) {
  (my MY $self, my $value) = @_;
}

MY->cli_run(\@ARGV) unless caller;
1;
