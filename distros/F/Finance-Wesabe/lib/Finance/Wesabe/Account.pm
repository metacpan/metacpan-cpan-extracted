package Finance::Wesabe::Account;

use Moose;
use Finance::Wesabe::Utils;
use Finance::Wesabe::Transaction;

=head1 NAME

Finance::Wesabe::Account - Class to represent a wesabe account

=head1 SYNOPSIS

    my $account = Finance::Wesabe::Account->new(
        content => $c, parent => $p
    );

=head1 DESCRIPTION

This modules provides access to your basic account information, including
individual transactions.

=head1 ACCESSORS

=over 4

=item * content - Hashref of data from the response

=item * parent - Parent object with acces to the user agent

=back

=cut

has content => ( is => 'ro', isa => 'HashRef' );

has parent => ( is => 'ro', isa => 'Object' );

=head1 ACCOUNT INFORMATION

=over 4

=item * name

=item * id

=item * guid

=item * txaction_count

=item * account_type

=item * account_number

=item * newest_txaction - A DateTime object

=item * oldest_txaction - A DateTime object

=item * last_uploaded_at - A DateTime object

=item * balance

=back

=cut

__PACKAGE__->mk_simple_field( qw( name txaction-count account-type account-number id guid ) );
__PACKAGE__->mk_deep_date_field( qw( newest-txaction oldest-txaction last-uploaded-at ) );
__PACKAGE__->mk_deep_field_map( ( 'current-balance' => 'balance' ) );

=head1 METHODS

=head2 transactions( )

Returns a list of L<Finance::Wesabe::Transaction> objects for transactions
associated with this account.

=cut

sub transactions {
    my $self = shift;

    if( !$self->{content}->{txactions} ) {
        return $self->parent->account( $self->content->{ id } )->transactions;
    }

    return map { Finance::Wesabe::Transaction->new( content => $_, parent => $self )  } @{ $self->{content}->{txactions}->{txaction} };
}

=head2 pretty_balance( )

Returns your balance in a nicely formatted string based on your preferenes.

=cut

sub pretty_balance {
    my $self = shift;
    return $self->_format_number( $self->balance );
}

sub _format_number {
    my( $self, $number ) = @_;
    my( $sign, $whole, $frac ) = $number =~ m{^([+-]?)(\d+)\.(\d+)};
    $sign ||= '';

    my $currency = $self->content->{ currency };
    my $del = $currency->{delimiter};
    1 while $whole =~ s{(\d)(\d\d\d)(?!\d)}{$1$del$2}g;

    my $places = $currency->{decimal_places};
    $frac = sprintf( "%0${places}d", $frac );

    my $sep = $currency->{separator};
    my $sym = $currency->{ symbol };
    return "$sign$sym$whole$sep$frac " . $currency->{content};
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
