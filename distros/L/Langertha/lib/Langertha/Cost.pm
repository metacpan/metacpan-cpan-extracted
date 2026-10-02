package Langertha::Cost;
# ABSTRACT: Immutable value object for the monetary cost of a single LLM call
our $VERSION = '0.503';
use Moose;

has input_usd       => ( is => 'ro', isa => 'Num', default => 0 );
has output_usd      => ( is => 'ro', isa => 'Num', default => 0 );
has cache_read_usd  => ( is => 'ro', isa => 'Num', default => 0 );
has cache_write_usd => ( is => 'ro', isa => 'Num', default => 0 );
has total_usd  => ( is => 'ro', isa => 'Num', lazy => 1, builder => '_build_total_usd' );
has currency   => ( is => 'ro', isa => 'Str', default => 'USD' );

sub _build_total_usd {
  my ($self) = @_;
  return $self->input_usd + $self->output_usd + $self->cache_read_usd + $self->cache_write_usd;
}

sub to_hash {
  my ($self) = @_;
  return {
    input_cost_usd       => $self->input_usd       + 0,
    output_cost_usd      => $self->output_usd      + 0,
    cache_read_cost_usd  => $self->cache_read_usd  + 0,
    cache_write_cost_usd => $self->cache_write_usd + 0,
    total_cost_usd       => $self->total_usd       + 0,
    currency             => $self->currency,
  };
}

# Make the object transparent to any JSON encoder configured with
# convert_blessed => 1 (the house default, see Langertha::Plugin::Langfuse).
# to_hash is the complete canonical representation, so this is a plain
# delegator — nothing is dropped.
sub TO_JSON { shift->to_hash }


__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Cost - Immutable value object for the monetary cost of a single LLM call

=head1 VERSION

version 0.503

=head2 input_usd

Cost of the input tokens. When the pricing rule had a cache rate, only the
tokens that were neither read from nor written to the prompt cache; otherwise
all of the usage's C<input_tokens>. Default C<0>.

=head2 output_usd

Cost of the output tokens. Default C<0>.

=head2 cache_read_usd

Cost of the prompt-cache reads (L<Langertha::Usage/cached_tokens>). C<0> unless
the pricing rule has a cache rate. Default C<0>.

=head2 cache_write_usd

Cost of the prompt-cache writes (L<Langertha::Usage/cache_write_tokens>). C<0>
unless the pricing rule has a cache rate. Default C<0>.

=head2 total_usd

The sum of the four amounts above, unless passed to C<new>.

=head2 currency

Default C<USD>.

=head2 to_hash

    { input_cost_usd => ..., output_cost_usd => ..., cache_read_cost_usd => ...,
      cache_write_cost_usd => ..., total_cost_usd => ..., currency => 'USD' }

The canonical hash; C<TO_JSON> returns the same.

=head1 SEE ALSO

=over

=item * L<Langertha::Pricing> - builds a Cost from a L<Langertha::Usage>

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
