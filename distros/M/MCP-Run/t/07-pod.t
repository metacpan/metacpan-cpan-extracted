use strict;
use warnings;
use Test::More;

use MCP::Run;
use MCP::Run::Bash;

# The SYNOPSIS is the first thing a reader copies. If it names a method that
# does not exist, the copy dies at runtime with "Can't locate object method",
# far away from the documentation that caused it. karr #40 was exactly that:
# MCP::Run::Bash documented $server->run, and neither MCP::Run::Bash, nor
# MCP::Run, nor MCP::Server has a method called run.
#
# This is a documentation guard, not a behaviour test: it fails when the
# documented calls and the code drift apart, and it does not care how the
# server behaves.

sub synopsis_of {
  my ($file) = @_;

  open my $fh, '<', $file or die "cannot read $file: $!";
  my $source = do { local $/; <$fh> };
  close $fh;

  # The block ends at the next =head1 of the same level - DESCRIPTION and the
  # attribute docs below it are prose, not copy-paste material.
  return $source =~ /^=head1 SYNOPSIS[ \t]*\n(.*?)(?=^=head1|\z)/ms ? $1 : '';
}

# Every method call in the SYNOPSIS has to resolve. Instance calls resolve on
# the documented class, class calls on the class they name.
sub methods_in {
  my ($synopsis) = @_;

  my @calls;
  while ($synopsis =~ /\$[A-Za-z_]\w*->(\w+)/g) {
    push @calls, ['instance', undef, $1];
  }
  while ($synopsis =~ /\b([A-Z]\w*(?:::\w+)*)->(\w+)/g) {
    push @calls, ['class', $1, $2];
  }
  return @calls;
}

for my $module (['MCP::Run', 'MCP/Run.pm'], ['MCP::Run::Bash', 'MCP/Run/Bash.pm']) {
  my ($class, $relative) = @$module;
  my $file = $INC{$relative} or die "$class was not loaded, cannot find its source";

  my $synopsis = synopsis_of($file);
  ok length $synopsis, "$class: SYNOPSIS found in $relative";

  my @calls = methods_in($synopsis);
  ok scalar @calls, "$class: SYNOPSIS contains at least one method call";

  for my $call (@calls) {
    my ($kind, $target, $method) = @$call;
    if ($kind eq 'instance') {
      $target = $class;
    }
    ok $target->can($method),
      "$class SYNOPSIS: $target->$method exists";
  }
}

done_testing;
