package Finance::Bank::Postbank_de::APIv1::Account;
use Moo;
use Filter::signatures;
no warnings 'experimental::signatures';
use feature 'signatures';
extends 'HAL::Resource';

our $VERSION = '0.57';

=head1 NAME

Finance::Bank::Postbank_de::APIv1::Account - Postbank Account

=head1 SYNOPSIS

    for my $account ($bp->get_accounts()) {
        print $account->productType;
        print $account->name;
        print $account->iban;
        print $account->currency;
        print $account->amount;
    }

=head1 ACCESSORS

=over 4

=item *

C<accountHolder>

=item *

=item *

C<name>

=item *

C<iban>

=item *

C<currency>

=item *

C<amount>

=item *

C<productType>

=back

=cut

has [ 'accountHolder', 'name', 'iban', 'currency', 'amount',
      'productType',
    ] => ( is => 'ro' );

=head1 METHODS

=head2 C<< ->transactions >>

Returns the transactions in this account as a list
of L<Finance::Bank::Postbank_de::APIv1::Transaction> objects.

=cut

sub transactions_future( $self ) {
    $self->fetch_resource_future( 'transactions' )->then(sub( $r ) {
        $self->inflate_list(
            'Finance::Bank::Postbank_de::APIv1::Transaction',
            $r->_embedded->{transactionDTOList}
        )
    });
}

sub transactions( $self ) {
    $self->transactions_future->get
}

sub transactions_csv_future( $self ) {
    $self->fetch_resource_future( 'transactions' )->then(sub( $r ) {
        my $tr = HAL::Resource->new( %$r );
        $self->ua->get( $tr->resource_url('transactions_csv' ));
        Future->done( $self->ua->content );
    });
}

=head2 C<< ->transactions_csv >>

=cut

sub transactions_csv( $self ) {
    $self->transactions_csv_future->get
}

sub transactions_xml_future( $self ) {
    $self->fetch_resource_future( 'transactions' )->then(sub( $r ) {
        my $tr = HAL::Resource->new( %$r );
        $self->ua->get( $tr->resource_url('transactions_xml' ));
        Future->done( $self->ua->content );
    });
}

=head2 C<< ->transactions_xml >>

=cut

sub transactions_xml( $self ) {
    $self->transactions_xml_future->get
}

=head2 C<< ->is_depot >>

Returns true if the account is a brokerage account.

=cut

sub is_depot( $self ) {
    $self->productType =~ /^depot$/i
}

=head2 C<< ->is_mortgage >>

Returns true if the account is a mortgage repayment account
("Baufinanzierung").

=cut

sub is_mortgage( $self ) {
    $self->productType =~ /^baufinanzierung$/i
}

=head2 C<< ->is_checking >>

Returns true if the account is a simple checking account.

=cut

sub is_checking( $self ) {
    $self->productType =~ /^giro$/i
}

=head2 C<< ->is_savings >>

Returns true if the account is a simple savings account.

=cut

sub is_savings( $self ) {
    $self->productType =~ /^spar$/i
}

=head2 C<< ->is_calldeposit >>

Returns true if the account is a call deposit account.

=cut

sub is_calldeposit( $self ) {
    $self->productType =~ /^tagesgeld$/i
}

1;

=head1 AUTHOR

Max Maischein, E<lt>corion@cpan.orgE<gt>

=head1 SEE ALSO

L<perl>, L<WWW::Mechanize>.

=head1 REPOSITORY

The public repository of this module is
L<https://github.com/Corion/Finance-Bank-Postbank_de>.

=head1 SUPPORT

The public support forum of this module is
L<https://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via the RT CPAN bug queue at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Finance-Bank-Postbank_de>
or via mail to L<finance-bank-postbank_de-Bugs@rt.cpan.org>.

=head1 COPYRIGHT (c)

Copyright 2003-2019 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut
