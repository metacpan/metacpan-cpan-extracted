package Finance::TW::TAIFEX::Product;
use strict;
use Any::Moose;

=head1 NAME

Finance::TW::TAIFEX::Contract - Product on TAIFEX

=head1 METHODS

=cut

with any_moose('X::Traits');

has name => (is => "ro", isa => "Str");

has exchange => (is => "ro", isa => "Finance::TW::TAIFEX");

has '+_trait_namespace' => ( default => 'Finance::TW::TAIFEX' );

sub _near_term {
    my ($self, $date) = @_;
    my $settlement = $self->find_settlement_day($date);
    if ( $date->day > $settlement->day ) {
        $settlement = $settlement->add( months => 1);
    }
    return $settlement;
}

=head2 near_term DATE

Returns the near term contract of the product at DATE in YYYYMM format.

=cut

sub near_term {
    my ($self, $date) = @_;
    return $self->_near_term($date)->strftime('%Y%m');
}

=head2 near_term_contract DATE

Returns the near term contract object for product at DATE.

=cut

sub near_term_contract {
    my ($self, $date) = @_;
    my $near_term = $self->_near_term($date);
    return Finance::TW::TAIFEX::Contract->new(
        product => $self,
        year => $near_term->year,
        month => $near_term->month);
}

=head2 find_settlement_day DATE

Find the settlement day of the near term contract at DATE.

=cut

sub find_settlement_day {
    my ($self, $date) = @_;
    my $settlement = $self->default_settlement_day($date);

    while (!$self->exchange->is_trading_day($settlement)) {
        $settlement->add( days => 1 );
    }

    return $settlement
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
