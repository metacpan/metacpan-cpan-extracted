package Finance::Dogechain::Address;
$Finance::Dogechain::Address::VERSION = '1.20210418.2306';
use Mojo::Base -base, -signatures, 'Finance::Dogechain::Base';

has 'address';

sub balance($self) {
    return $self->return_field_if_success( '/address/balance/' . $self->address, 'balance' );
}

sub received($self) {
    return $self->return_field_if_success( '/address/received/' . $self->address, 'received' );
}

sub sent($self) {
    return $self->return_field_if_success( '/address/sent' . $self->address, 'sent' );
}

sub unspent($self) {
    return [
        map {
            $_->{value} / 100000000;
        }
        $self->return_field_if_success( '/unspent/' . $self->address, 'unspent_outputs' )->@*
    ];
}

sub TO_JSON($self) {
    return '[Finance::Dogechain::Address](address => ' . $self->address . ')';
}

'to the moon';
__END__
=pod

=head1 NAME

Finance::Dogechain::Address - class representing addresses in the Dogechain API

=head1 SYNOPSIS

    use Finance::Dogechain::Address;

    my $address = Finance::Dogechain::Address(
        address => 'DDMczmdPkpHMCaAJGEno11hMRc46A2uKsj',
    );

    for my $transaction ($address->{txs}->@*) { ... }

=head1 DESCRIPTION

C<Finance::Dogechain::Address> represents transactions in the Dogechain API. It
inherits methods from C<Finance::Dogechain::Base> and provides several of its
own.

=head1 METHODS

=head2 new( ua => ..., base_url => ..., address => '...' )

Creates a new instance of this object. You I<must> provide a C<address>
parameter, which is either a valid address in the Dogecoin public
ledger.

Other default constructor values are:

=over 4

=item * C<ua>, a user agent. Defaults to an instance of L<Mojo::UserAgent>.

=item * C<base_url>, the base URL path of the dogechain.info API (or an equivalent).

=back

These attributes are available by instance methods C<address()>, C<ua()>, and C<base_url()>.

=head2 balance()

Returns a floating point value representing the current balance (number of
Dogecoins) that this address contains.

Returns an undefined value (C<undef> in scalar context or an empty list in list
context) if the HTTP call did not succeed.

Returns C<0> if the HTTP call did succeed but the API returned an unsuccessful payload.

=head2 received()

Returns a floating point value representing the total number of Dogecoins that this
address has received.

Returns an undefined value (C<undef> in scalar context or an empty list in list
context) if the HTTP call did not succeed.

Returns C<0> if the HTTP call did succeed but the API returned an unsuccessful payload.

=head2 sent()

Returns a floating point value representing the total number of Dogecoins that this
address has sent.

Returns an undefined value (C<undef> in scalar context or an empty list in list
context) if the HTTP call did not succeed.

Returns C<0> if the HTTP call did succeed but the API returned an unsuccessful payload.

=head2 unspent()

Returns an array reference of values from transaction outputs that this address has not yet spent.

Returns an undefined value (C<undef> in scalar context or an empty list in list
context) if the HTTP call did not succeed.

Returns C<0> if the HTTP call did succeed but the API returned an unsuccessful payload.

=head2 TO_JSON()

Returns a string representation of this object (its class and C<address>) so that
you can serialize this object with L<JSON>.

=head1 COPYRIGHT & LICENSE

Copyright 2021 chromatic, some rights reserved.

This program is free software. You can redistribute it and/or modify it under
the same terms as Perl 5.32.

=cut
