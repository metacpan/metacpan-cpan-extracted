package Finance::AMEX::Transaction::EPTRN::Base;
$Finance::AMEX::Transaction::EPTRN::Base::VERSION = '0.004';
use strict;
use warnings;

# ABSTRACT: Parse AMEX Transaction/Invoice Level Reconciliation (EPTRN)

sub new {
  my ($class, %props) = @_;
  my $self = bless {
    _line => $props{line},
  }, $class;

  return $self;
}

sub line {
  my ($self) = @_;
  return $self->{_line};
}

sub _get_column {
  my ($self, $field) = @_;
  my $map = $self->field_map->{$field};

  # if the line is not long enough to handle the start of the field,
  # it is an optional field that we don't have
  if (length($self->{_line}) < $map->[0]) {
    return '';
  }

  my $ret = substr($self->{_line}, $map->[0] - 1, $map->[1]);
  $ret =~ s{\s+\z}{};
  return $ret;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Finance::AMEX::Transaction::EPTRN::Base - Parse AMEX Transaction/Invoice Level Reconciliation (EPTRN)

=head1 VERSION

version 0.004

=head1 DESCRIPTION

Don't use this module directly, it is the base module for L<Finance::AMEX::Transaction::EPTRN::Header>, L<Finance::AMEX::Transaction::EPTRN::Summary>, L<Finance::AMEX::Transaction::EPTRN::Detail::ChargeSummary>, L<Finance::AMEX::Transaction::EPTRN::Detail::RecordSummary>, L<Finance::AMEX::Transaction::EPTRN::Detail::Chargeback>, L<Finance::AMEX::Transaction::EPTRN::Detail::Adjustment>, L<Finance::AMEX::Transaction::EPTRN::Detail::Other>, L<Finance::AMEX::Transaction::EPTRN::Trailer>, or L<Finance::AMEX::Transaction::EPTRN::Unknown> objects.

=head1 METHODS

=head2 new

The shared new method.

=head2 line

The shared line method.

=head1 NAME

Finance::AMEX::Transaction::EPTRN::Base - Shared methods for AMEX Transaction/Invoice Level Reconciliation (EPTRN) records.

=head1 AUTHOR

Tom Heady <cpan@punch.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by ZipRecruiter.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
