package Finance::GDAX::API::Time;
our $VERSION = '0.01';
use 5.20.0;
use warnings;
use Moose;
use Finance::GDAX::API;
use namespace::autoclean;

extends 'Finance::GDAX::API';

sub get {
    my $self = shift;
    $self->method('GET');
    $self->path('/time');
    return $self->send;
}

__PACKAGE__->meta->make_immutable;
1;

=head1 NAME

Finance::GDAX::API::Time - Time

=head1 SYNOPSIS

  use Finance::GDAX::API::Time;

  $time = Finance::GDAX::API::Time->new;

  # Get current time
  $time_hash = $time->get;

=head2 DESCRIPTION

Gets the time reported by GDAX.

=head1 METHODS

=head2 C<get>

Returns a hash representing the GDAX API server's notion of current
time.

From the GDAX API:

  {
    "iso": "2015-01-07T23:47:25.201Z",
    "epoch": 1420674445.201
  }

=cut


=head1 AUTHOR

Mark Rushing <mark@orbislumen.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Home Grown Systems, SPC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

