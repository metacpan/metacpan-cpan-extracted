package Finance::AMEX::Transaction::CBNOT::Base;
$Finance::AMEX::Transaction::CBNOT::Base::VERSION = '0.003';
use strict;
use warnings;

# ABSTRACT: Parse AMEX Chargeback Notification Files (CBNOT) Base methods

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

  my $ret = substr($self->{_line}, $map->[0] - 1, $map->[1]);
  $ret =~ s{\s+\z}{};
  return $ret;
}

sub REC_TYPE {
  my ($self) = @_;
  return $self->_get_column('REC_TYPE');
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Finance::AMEX::Transaction::CBNOT::Base - Parse AMEX Chargeback Notification Files (CBNOT) Base methods

=head1 VERSION

version 0.003

=head1 DESCRIPTION

Don't use this module directly, it is the base module for L<Finance::AMEX::Transaction::CBNOT::Header>, L<Finance::AMEX::Transaction::CBNOT::Detail>, and L<Finance::AMEX::Transaction::CBNOT::Trailer> objects.

=head1 METHODS

=head2 new

The shared new method.

=head2 line

The shared line method.

=head2 REC_TYPE

The shared REC_TYPE method.

=head1 NAME

Finance::AMEX::Transaction::CBNOT::Base - Shared methods for AMEX chargeback notification file records.

=head1 AUTHOR

Tom Heady <theady@ziprecruiter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by ZipRecruiter.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
