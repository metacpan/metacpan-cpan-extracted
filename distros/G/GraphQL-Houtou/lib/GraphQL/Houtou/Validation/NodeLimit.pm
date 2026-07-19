package GraphQL::Houtou::Validation::NodeLimit;

use 5.014;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(check_query_nodes);

# The depth limit bounds nesting but not breadth: an alias-flooded query
# like { a:f b:f c:f ... } (optionally repeated under a shallow nesting)
# stays within the depth limit while forcing a huge amount of resolution
# and a huge response. This validator caps the total number of field
# selections an operation resolves, counting fragment spreads by
# expansion so { ...F ...F ...F } cannot multiply cheaply. It is a coarse
# DoS bound, not a cost model. The separate XS weighted-cost walk accounts
# for field cost and estimated list fan-out; both limits are enforced.
use constant DEFAULT_MAX_NODES => 10_000;

sub check_query_nodes {
  my ($ast, %opts) = @_;
  my $max_nodes = exists $opts{max_nodes} ? $opts{max_nodes} : DEFAULT_MAX_NODES;
  return () unless defined $max_nodes;

  my %fragments = map { $_->{name} => $_ }
    grep { ($_->{kind} // '') eq 'fragment' } @{ $ast || [] };

  my @errors;
  for my $node (@{ $ast || [] }) {
    next unless ($node->{kind} // '') eq 'operation';
    # Cap the walk itself at max_nodes+1 so a pathological document cannot
    # make counting expensive: as soon as the budget is blown we stop.
    my $count = _count_nodes($node->{selections} // [], \%fragments, {}, $max_nodes + 1);
    if ($count > $max_nodes) {
      my $name = $node->{name};
      my $label = defined $name ? qq("$name") : 'anonymous operation';
      push @errors, {
        message => "Query has too many field selections (exceeds maximum of $max_nodes) in $label",
      };
    }
  }
  return @errors;
}

# Returns the number of field selections reachable from $selections,
# stopping early once $budget is exceeded (the returned value is then
# just "> max_nodes", which is all the caller needs).
sub _count_nodes {
  my ($selections, $fragments, $visited, $budget) = @_;
  my $count = 0;
  for my $sel (@{ $selections || [] }) {
    my $kind = $sel->{kind} // '';
    if ($kind eq 'field') {
      $count++;
      $count += _count_nodes($sel->{selections}, $fragments, $visited, $budget - $count)
        if $sel->{selections};
    } elsif ($kind eq 'inline_fragment') {
      $count += _count_nodes($sel->{selections} // [], $fragments, $visited, $budget - $count);
    } elsif ($kind eq 'fragment_spread') {
      my $name = $sel->{name} // '';
      next if $visited->{$name};
      my $frag = $fragments->{$name} or next;
      local $visited->{$name} = 1;
      $count += _count_nodes($frag->{selections} // [], $fragments, $visited, $budget - $count);
    }
    return $count if $count > $budget;
  }
  return $count;
}

1;

__END__

=encoding utf-8

=head1 NAME

GraphQL::Houtou::Validation::NodeLimit - query field-count limit validator

=head1 SYNOPSIS

    use GraphQL::Houtou::Validation::NodeLimit qw(check_query_nodes);

    my $ast = GraphQL::Houtou::parse($query_string);
    my @errors = check_query_nodes($ast, max_nodes => 5000);

=head1 DESCRIPTION

Caps the total number of field selections an operation resolves, so a
breadth-flooded query (many aliases of the same field, optionally
multiplied through repeated fragment spreads) cannot exhaust CPU and
memory while staying under the depth limit. Fragment spreads are counted
by expansion; a spread already on the current path is not re-counted
(cycles are rejected separately by the main validator).

The default maximum is 10,000. Pass C<max_nodes =E<gt> undef> to disable
the check. This is a coarse denial-of-service bound rather than a
weighted complexity model.

=head1 FUNCTIONS

=head2 check_query_nodes($ast, %opts)

Accepts a parsed AST (arrayref of definition nodes) and an optional
C<max_nodes>. Returns a list of error hashrefs (empty when within the
limit).

=cut
