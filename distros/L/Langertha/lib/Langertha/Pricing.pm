package Langertha::Pricing;
# ABSTRACT: Model→price catalog producing Langertha::Cost from Langertha::Usage
our $VERSION = '0.503';
use Moose;
use Langertha::Cost;

# Map of model id → { input_per_million => N, output_per_million => N,
# cached_input_per_million => N, cache_write_per_million => N }. The last two
# are optional. All keys are USD per 1,000,000 tokens.
has rules => (
  is      => 'ro',
  isa     => 'HashRef',
  default => sub { {} },
);

# Optional fallback rule applied when a model id is unknown.
has default_rule => (
  is      => 'ro',
  isa     => 'Maybe[HashRef]',
  default => sub { undef },
);

sub rule_for {
  my ($self, $model) = @_;
  return $self->rules->{$model} if defined $model && exists $self->rules->{$model};
  return $self->default_rule;
}

sub cost_for {
  my ($self, $usage, $model) = @_;
  my $rule = $self->rule_for($model) || {};
  my $ipm = 0 + ( $rule->{input_per_million}  // 0 );
  my $opm = 0 + ( $rule->{output_per_million} // 0 );
  my $output_usd = ( $usage->output_tokens / 1_000_000 ) * $opm;

  # A rule without a cache rate prices input_tokens as a whole, as it always
  # did. A rule with one splits the cache counts out of input_tokens (or adds
  # them, where the wire counts them beside it — Usage->input_includes_cache)
  # so no token is priced twice. A missing rate falls back to the input rate:
  # no discount the rule did not state. (k263, ADR 0031)
  my $cached_rate = $rule->{cached_input_per_million};
  my $write_rate  = $rule->{cache_write_per_million};
  unless ( defined $cached_rate || defined $write_rate ) {
    return Langertha::Cost->new(
      input_usd  => ( $usage->input_tokens / 1_000_000 ) * $ipm,
      output_usd => $output_usd,
    );
  }
  my $cached = $usage->cached_tokens      // 0;
  my $write  = $usage->cache_write_tokens // 0;
  return Langertha::Cost->new(
    input_usd       => ( $usage->uncached_input_tokens / 1_000_000 ) * $ipm,
    output_usd      => $output_usd,
    cache_read_usd  => ( $cached / 1_000_000 ) * ( 0 + ( $cached_rate // $ipm ) ),
    cache_write_usd => ( $write  / 1_000_000 ) * ( 0 + ( $write_rate  // $ipm ) ),
  );
}


__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Pricing - Model→price catalog producing Langertha::Cost from Langertha::Usage

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    my $pricing = Langertha::Pricing->new(
      rules => {
        'my-model' => {
          input_per_million        => 3,
          output_per_million       => 15,
          cached_input_per_million => 0.30,   # optional
          cache_write_per_million  => 3.75,   # optional
        },
      },
    );
    my $cost = $pricing->cost_for( $response->usage, $response->model );
    printf "%.6f %s\n", $cost->total_usd, $cost->currency;

=head1 DESCRIPTION

Turns a L<Langertha::Usage> into a L<Langertha::Cost> from price rules you
supply. Langertha ships no prices: provider prices change too often.

=head2 rules

HashRef of model id to rule. A rule is a HashRef of USD per 1,000,000 tokens:

=over

=item * C<input_per_million> - input (prompt) tokens

=item * C<output_per_million> - output (completion) tokens

=item * C<cached_input_per_million> - optional; tokens read from the prompt
cache (L<Langertha::Usage/cached_tokens>)

=item * C<cache_write_per_million> - optional; tokens written to the prompt
cache (L<Langertha::Usage/cache_write_tokens>)

=back

A missing C<input_per_million> or C<output_per_million> counts as C<0>.

=head2 default_rule

Rule used when the model has no entry in L</rules>. C<undef> by default, so an
unknown model costs nothing.

=head2 rule_for

    my $rule = $pricing->rule_for($model);

The rule for C<$model>, else L</default_rule>.

=head2 cost_for

    my $cost = $pricing->cost_for( $usage, $model );

Prices C<$usage> with the rule for C<$model> and returns a L<Langertha::Cost>.

A rule with neither cache key prices all of C<input_tokens>
at C<input_per_million>, whatever part of it was cached, and sets no cache
amounts.

A rule with at least one cache key prices each token once, in one of three
amounts. C<input_usd> covers L<Langertha::Usage/uncached_input_tokens>;
C<cache_read_usd> covers the cache reads at C<cached_input_per_million>;
C<cache_write_usd> covers the cache writes at C<cache_write_per_million>. A
cache key the rule does not have falls back to C<input_per_million>, so no
discount is assumed. On wires that count the cache tokens inside the input
count (OpenAI, Open-Responses, Gemini, AKI.IO native) they are taken out of
it; on Anthropic's wire, which counts them beside it, they are added (see
L<Langertha::Usage/input_includes_cache>).

=head1 SEE ALSO

=over

=item * L<Langertha::Usage>

=item * L<Langertha::Cost>

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
