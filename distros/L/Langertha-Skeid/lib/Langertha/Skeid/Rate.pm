package Langertha::Skeid::Rate;
our $VERSION = '0.005';
# ABSTRACT: The request rate of a policy: its shape, and whether one rate is within another
use strict;
use warnings;
use Carp qw(croak);
use POSIX ();
use Scalar::Util qw(looks_like_number);


sub normalize {
  my ($class, $rate, $where) = @_;
  return undef unless defined $rate;
  my $at = defined($where) && length($where) ? "rate of $where" : 'rate';
  croak "$at must be a mapping of per_s, burst, per_min" unless ref($rate) eq 'HASH';
  my @unknown = grep { !/\A(?:per_s|burst|per_min)\z/ } sort keys %$rate;
  croak "$at: unknown field " . join(', ', @unknown) if @unknown;
  for my $field (qw( per_s per_min )) {
    next unless defined $rate->{$field};
    croak "$at: $field must be a number above 0"
      unless !ref($rate->{$field}) && looks_like_number($rate->{$field}) && $rate->{$field} > 0;
  }
  croak "$at needs per_s or per_min" unless defined($rate->{per_s}) || defined($rate->{per_min});
  my $burst;
  if (defined $rate->{per_s}) {
    $burst = defined($rate->{burst}) ? $rate->{burst} : POSIX::ceil($rate->{per_s});
    croak "$at: burst must be a whole number of at least 1"
      unless !ref($burst) && looks_like_number($burst) && $burst >= 1 && $burst == int($burst);
  } elsif (defined $rate->{burst}) {
    croak "$at: burst needs per_s";
  }
  return {
    (defined($rate->{per_s})   ? (per_s => 0 + $rate->{per_s}, burst => 0 + $burst) : ()),
    (defined($rate->{per_min}) ? (per_min => 0 + $rate->{per_min}) : ()),
  };
}


sub within {
  my ($class, $spec, $ceiling) = @_;
  my $row = $class->normalize($spec, 'the row');
  return $row unless $ceiling;
  if (defined($row->{per_s}) && !defined($spec->{burst}) && defined($ceiling->{burst})
      && $ceiling->{burst} < $row->{burst}) {
    $row->{burst} = $ceiling->{burst};
  }
  for my $part (qw( per_s burst per_min )) {
    next unless defined($row->{$part}) && defined($ceiling->{$part});
    return undef if $row->{$part} > $ceiling->{$part};
  }
  my %rate = (%$ceiling, %$row);
  # per_s and its burst go together: a row that sets only per_min keeps the ceiling's pair.
  return \%rate;
}


sub print {
  my ($class, $rate) = @_;
  return '' unless $rate;
  return join '/', map { $rate->{$_} // '' } qw( per_s burst per_min );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Skeid::Rate - The request rate of a policy: its shape, and whether one rate is within another

=head1 VERSION

version 0.005

=head1 DESCRIPTION

A request rate (skeid k125) is a mapping of C<per_s> with its C<burst> and/or C<per_min>; see
L<Langertha::Skeid/Per-Key Routing Policy>. This module checks its shape, and -- for a rate that
comes from a customer-source row (skeid k126) -- whether it stays within the rate of its policy.

=head2 normalize

  my $rate = Langertha::Skeid::Rate->normalize($spec, $where);   # undef for none

The rate in its normalized form, C<< { per_s, burst, per_min } >> with only the parts given;
C<burst> defaults to C<per_s> rounded up. Croaks, naming C<$where>, on anything else: not a
mapping, an unknown field, a C<per_s> or C<per_min> not above 0, neither of them, a C<burst> that
is no whole number of at least 1, or a C<burst> without C<per_s>.

=head2 within

  my $effective = Langertha::Skeid::Rate->within($row_spec, $ceiling);   # undef: looser

The rate a key gets when its own C<$row_spec> (raw, as L</normalize> takes it) may only tighten
the normalized C<$ceiling> of its policy (undef: no limit, so any rate is within it). Each part
the ceiling has is kept, or replaced by a part of the row that is not above it; a part only the
row has is added. A C<burst> the row leaves out is the ceiling's C<burst> when that is smaller
than the default. Returns the effective normalized rate, or undef when the row asks for more
than the ceiling allows anywhere. Croaks like L</normalize> on a malformed row spec.

=head2 print

  my $text = Langertha::Skeid::Rate->print($rate);   # '2/10/60', '' for none

A string that is equal for equal rates, for fingerprints and bucket resets.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/langertha-skeid/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
