#!/usr/bin/env perl
package Test::Cool::unknown;
no warnings qw(redefine);
use Getopt::App;
sub getopt_subcommands { [] }

sub getopt_unknown_subcommand {
  my ($self, $argv) = @_;
  $self->{unknown} = int @$argv;
  return $argv->[0] eq 'die' ? die 'not cool' : $argv->[0] =~ m!^(\d+)! ? $argv->[0] : undef;
}

run(sub { say shift->{unknown} ? 'unknown' : 'ok'; return 0 });
