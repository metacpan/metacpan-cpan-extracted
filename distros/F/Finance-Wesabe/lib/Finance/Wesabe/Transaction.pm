package Finance::Wesabe::Transaction;

use Moose;
use Finance::Wesabe::Utils;

=head1 NAME

Finance::Wesabe::Transaction - Class to represent a transaction

=head1 SYNOPSIS

    my $txn = Finance::Wesabe::Transaction->new(
        content => $c, parent => $p
    );

=head1 DESCRIPTION

This class represents a single transaction for a given account.

=head1 ACCESSORS

=over 4

=item * content - Hashref of data from the response

=item * parent - Parent object with acces to the user agent

=back

=cut

has content => ( is => 'ro', isa => 'HashRef' );

has parent => ( is => 'ro', isa => 'Object' );

=head1 TRANSACTION INFORMATION

=over 4

=item * raw_name

=item * guid

=item * memo

=item * note

=item * raw_txntype

=item * amount

=item * date - A DateTime object

=item * original_date - A DateTime object

=back

=cut

__PACKAGE__->mk_simple_field( qw( memo raw-name guid raw-txntype note ) );
__PACKAGE__->mk_deep_field( qw( amount ) );
__PACKAGE__->mk_simple_date_field( qw( date original-date ) );

=head1 METHODS

=head2 pretty_amount( )

Returns the transaction amount in a nicely formatted string based on your
preferenes.

=cut

sub pretty_amount {
    my $self = shift;
    return $self->parent->_format_number( $self->amount );
}

=head2 tags( )

Returns a list of tag names associated with this transaction.

=cut

sub tags {
    my $self = shift;

    my $tags = $self->content->{ tags }->{ tag };
    return $tags->{ name } unless ref $tags eq 'ARRAY';
    return map { $_->{ name } } @$tags;
}

=head2 is_transfer( )

Returns a boolean indicating if this transaction is a transfer.

=cut

sub is_transfer {
    return exists shift->content->{ transfer };
}

no Moose;

__PACKAGE__->meta->make_immutable;

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2009-2010 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
