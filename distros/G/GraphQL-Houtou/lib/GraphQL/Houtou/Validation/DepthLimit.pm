package GraphQL::Houtou::Validation::DepthLimit;

use 5.014;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(check_query_depth);

use constant DEFAULT_MAX_DEPTH => 15;

sub check_query_depth {
  my ($ast, %opts) = @_;
  my $max_depth = exists $opts{max_depth} ? $opts{max_depth} : DEFAULT_MAX_DEPTH;
  return () unless defined $max_depth;

  my %fragments = map { $_->{name} => $_ }
    grep { ($_->{kind} // '') eq 'fragment' } @{ $ast || [] };

  my @errors;
  for my $node (@{ $ast || [] }) {
    next unless ($node->{kind} // '') eq 'operation';
    my $depth = _compute_max_depth($node->{selections} // [], \%fragments, {});
    if ($depth > $max_depth) {
      my $name = $node->{name};
      my $label = defined $name ? qq("$name") : 'anonymous operation';
      push @errors, {
        message => "Query depth $depth exceeds maximum allowed depth of $max_depth in $label",
      };
    }
  }
  return @errors;
}

sub _compute_max_depth {
  my ($selections, $fragments, $visited) = @_;
  my $max = 0;
  for my $sel (@{ $selections || [] }) {
    my $kind = $sel->{kind} // '';
    my $depth;
    if ($kind eq 'field') {
      $depth = $sel->{selections}
        ? 1 + _compute_max_depth($sel->{selections}, $fragments, $visited)
        : 1;
    } elsif ($kind eq 'inline_fragment') {
      $depth = _compute_max_depth($sel->{selections} // [], $fragments, $visited);
    } elsif ($kind eq 'fragment_spread') {
      my $name = $sel->{name} // '';
      next if $visited->{$name};
      my $frag = $fragments->{$name} or next;
      local $visited->{$name} = 1;
      $depth = _compute_max_depth($frag->{selections} // [], $fragments, $visited);
    }
    $max = $depth if defined $depth && $depth > $max;
  }
  return $max;
}

1;

__END__

=encoding utf-8

=head1 NAME

GraphQL::Houtou::Validation::DepthLimit - query depth limit validator

=head1 SYNOPSIS

    use GraphQL::Houtou::Validation::DepthLimit qw(check_query_depth);

    my $ast = GraphQL::Houtou::parse($query_string);
    my @errors = check_query_depth($ast, max_depth => 10);
    if (@errors) {
        return { data => undef, errors => \@errors };
    }

=head1 DESCRIPTION

Validates that a parsed GraphQL document does not exceed a maximum field
nesting depth.  Fragments and inline fragments are followed without adding
depth themselves; only concrete field selections increment the depth counter.

The default maximum depth is 10.  Pass C<max_depth =E<gt> undef> to disable the
check entirely.

=head1 FUNCTIONS

=head2 check_query_depth($ast, %opts)

Accepts a parsed AST (arrayref of definition nodes as returned by
C<GraphQL::Houtou::parse()>) and optional named arguments:

=over 4

=item max_depth

Maximum allowed nesting depth.  Defaults to 15.  Set to C<undef> to disable.

=back

Returns a list of error hashrefs (each with a C<message> key) — empty list
means the document is within the limit.

=head1 SEE ALSO

L<GraphQL::Houtou>

=cut
