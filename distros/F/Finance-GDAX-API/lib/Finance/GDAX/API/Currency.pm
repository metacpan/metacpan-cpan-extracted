package Finance::GDAX::API::Currency;
our $VERSION = '0.01';
use 5.20.0;
use warnings;
use Moose;
use Finance::GDAX::API;
use namespace::autoclean;

extends 'Finance::GDAX::API';

sub list {
    my $self = shift;
    $self->method('GET');
    $self->path('/currencies');
    return $self->send;
}

__PACKAGE__->meta->make_immutable;
1;

=head1 NAME

Finance::GDAX::API::Currency - Currencies

=head1 SYNOPSIS

  use Finance::GDAX::API::Currency;

  $currency = Finance::GDAX::API::Currency->new;

  # List all currencies
  $currencies = $currency->list;

=head2 DESCRIPTION

Work with GDAX currencies.

=head1 METHODS

=head2 C<list>

From the GDAX API:

Returns an array of hashes of known currencies.

Currency Codes

Currency codes will conform to the ISO 4217 standard where
possible. Currencies which have or had no representation in ISO 4217
may use a custom code.

  [{
    "id": "BTC",
    "name": "Bitcoin",
    "min_size": "0.00000001"
  }, {
    "id": "USD",
    "name": "United States Dollar",
    "min_size": "0.01000000"
  }]

=cut


=head1 AUTHOR

Mark Rushing <mark@orbislumen.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Home Grown Systems, SPC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

