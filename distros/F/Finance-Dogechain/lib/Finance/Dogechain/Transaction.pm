package Finance::Dogechain::Transaction;
$Finance::Dogechain::Transaction::VERSION = '1.20210605.1754';
use Mojo::Base -base, -signatures, 'Finance::Dogechain::Base';
use Finance::Dogechain::Address;

has 'tx_id';
has 'transaction', sub($self) {
    my $tx = $self->return_field_if_success( '/transaction/' . $self->tx_id, 'transaction' );

    convert_addresses_in_place( $tx->{inputs}, $tx->{outputs} ) if $tx;

    return $tx;
};

sub inputs($self) {
    return $self->transaction->{inputs};
}

sub outputs($self) {
    return $self->transaction->{outputs};
}

sub convert_addresses_in_place(@items) {
    while (my $items = shift @items) {
        for my $item (@$items) {
            say $item->{address};
            $item->{address} = Finance::Dogechain::Address->new( address => $item->{address} );
        }
    }
}

sub TO_JSON($self) {
    return '[Finance::Dogechain::Transaction](tx_id => ' . $self->tx_id . ')';
}

'to the moon';
__END__
=pod

=head1 NAME

Finance::Dogechain::Transaction - class representing transactions in the Dogechain API

=head1 SYNOPSIS

    use Finance::Dogechain::Transaction;

    my $tx = Finance::Dogechain::Transaction->new(
        tx_id => '9b7707711014114bdfc6352d803e3175a8dfa25eb2b7fcfb6e29e0a031cf2d27'
    );

    for my $input_address  (map { $_->{address} } $tx->inputs->@*)  { ... }
    for my $output_address (map { $_->{address} } $tx->outputs->@*) { ... }

=head1 DESCRIPTION

C<Finance::Dogechain::Transaction> represents transactions in the Dogechain
API. It inherits methods from C<Finance::Dogechain::Base> and provides several
of its own.

=head1 METHODS

=head2 new( ua => ..., base_url => ..., tx_id => '...' )

Creates a new instance of this object. You I<must> provide a C<tx_id>
parameter, which is a hash which represents a valid transaction in the Dogecoin
public ledger.

Other default constructor values are:

=over 4

=item * C<ua>, a user agent. Defaults to an instance of L<Mojo::UserAgent>.

=item * C<base_url>, the base URL path of the dogechain.info API (or an equivalent).

=back

These attributes are available by instance methods C<tx_id()>, C<ua()>, and C<base_url()>.

=head2 transaction()

Returns a JSON data structure representing the transaction corresponding to the
C<tx_id>, if that transaction is valid and can be accessed. Dogecoin addresses
in the transaction's inputs and outputs will be replaced with
C<Finance::Dogechain::Address> objects when possible.

Returns an undefined value (C<undef> in scalar context or an empty list in list
context) if the HTTP call did not succeed.

Returns C<0> if the HTTP call did succeed but the API returned an unsuccessful payload.

=head2 inputs()

Returns a reference to an array of hashes representing transaction inputs.

=head2 outputs()

Returns a reference to an array of hashes representing transaction outputs.

=head2 TO_JSON()

Returns a string representation of this object (its class and C<tx_id>) so that
you can serialize this object with L<JSON>.

=head1 COPYRIGHT & LICENSE

Copyright 2021 chromatic, some rights reserved.

This program is free software. You can redistribute it and/or modify it under
the same terms as Perl 5.32.

=cut
