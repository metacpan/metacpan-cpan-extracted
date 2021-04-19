package Finance::Dogechain::Block;
$Finance::Dogechain::Block::VERSION = '1.20210418.2306';
use Mojo::Base -base, -signatures, 'Finance::Dogechain::Base';
use Finance::Dogechain::Transaction;

has 'block_id';

sub block($self) {
    my $block = $self->return_field_if_success( '/block/' . $self->block_id, 'block' );
    say JSON->new->pretty->encode( $block );

    if ($block) {
        $self->convert_transactions_in_place( $block->{txs} );
    }

    return $block;
}

sub convert_transactions_in_place($self, $txs) {
    while (my ($i, $tx_id) = each @$txs) {
        $txs->[$i] = Finance::Dogechain::Transaction->new( tx_id => $tx_id );
    }
}

sub TO_JSON($self) {
    return '[Finance::Dogechain::Block](block_id => ' . $self->block_id . ')';
}

'to the moon';
__END__
=pod

=head1 NAME

Finance::Dogechain::Block - class representing blocks in the Dogechain API

=head1 SYNOPSIS

    use Finance::Dogechain::Block;

    my $block = Finance::Dogechain::Block(
        block_id => '2750235'
    );

    for my $transaction ($block->{txs}->@*) { ... }

=head1 DESCRIPTION

C<Finance::Dogechain::Block> represents transactions in the Dogechain API. It
inherits methods from C<Finance::Dogechain::Base> and provides several of its
own.

=head1 METHODS

=head2 new( ua => ..., base_url => ..., block_id => '...' )

Creates a new instance of this object. You I<must> provide a C<block_id>
parameter, which is either the hash representing a block in the Dogecoin public
ledger or the height of a block in the ledger.

Other default constructor values are:

=over 4

=item * C<ua>, a user agent. Defaults to an instance of L<Mojo::UserAgent>.

=item * C<base_url>, the base URL path of the dogechain.info API (or an equivalent).

=back

These attributes are available by instance methods C<block_id()>, C<ua()>, and C<base_url()>.

=head2 block()

Returns a JSON data structure representing the block corresponding to the
C<block_id>, if that block is valid and can be accessed. Dogecoin transactions
in the block will be replaced with C<Finance::Dogechain::Transaction> objects
when possible.

Returns an undefined value (C<undef> in scalar context or an empty list in list
context) if the HTTP call did not succeed.

Returns C<0> if the HTTP call did succeed but the API returned an unsuccessful payload.

=head2 TO_JSON()

Returns a string representation of this object (its class and C<block_id>) so that
you can serialize this object with L<JSON>.

=head1 COPYRIGHT & LICENSE

Copyright 2021 chromatic, some rights reserved.

This program is free software. You can redistribute it and/or modify it under
the same terms as Perl 5.32.

=cut
