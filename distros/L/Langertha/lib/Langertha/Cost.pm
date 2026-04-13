package Langertha::Cost;
# ABSTRACT: Immutable value object for the monetary cost of a single LLM call
our $VERSION = '0.401';
use Moose;

has input_usd  => ( is => 'ro', isa => 'Num', default => 0 );
has output_usd => ( is => 'ro', isa => 'Num', default => 0 );
has total_usd  => ( is => 'ro', isa => 'Num', lazy => 1, builder => '_build_total_usd' );
has currency   => ( is => 'ro', isa => 'Str', default => 'USD' );

sub _build_total_usd {
  my ($self) = @_;
  return $self->input_usd + $self->output_usd;
}

sub to_hash {
  my ($self) = @_;
  return {
    input_cost_usd  => $self->input_usd  + 0,
    output_cost_usd => $self->output_usd + 0,
    total_cost_usd  => $self->total_usd  + 0,
    currency        => $self->currency,
  };
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Cost - Immutable value object for the monetary cost of a single LLM call

=head1 VERSION

version 0.401

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
