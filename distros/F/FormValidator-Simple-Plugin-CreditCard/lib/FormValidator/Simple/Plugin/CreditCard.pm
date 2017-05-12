package FormValidator::Simple::Plugin::CreditCard;
use strict;
use FormValidator::Simple::Exception;
use FormValidator::Simple::Constants;
require Business::CreditCard;

our $VERSION = '0.03';

my $__creditcard_types = {
    VISA     => 'VISA card',
    MASTER   => 'MasterCard',
    DISCOVER => 'Discovoer card',
    AMEX     => 'American Express card',
    DINERS   => "Diner's Club/Carte Blanche",
    ENROUTE  => 'enRoute',
    JCB      => 'JCB',
    BANKCARD => 'BankCard',
    SWITCH   => 'Switch',
    SOLO     => 'Solo',
};

sub __creditcard_get_type {
    my ($self, $abbreviation) = @_;
    if ( exists $__creditcard_types->{$abbreviation} ) {
        return $__creditcard_types->{$abbreviation};
    }
    else {
        FormValidator::Simple::Exception->throw(
            qq/Unknown Card Type "$abbreviation"./
        );
    }
}

sub CREDIT_CARD {
    my ($self, $params, $args) = @_;
    my $data = $params->[0];
    if ($args && scalar(@$args) > 0) {
        foreach my $type (@$args) {
            if ($self->__creditcard_get_type($type) eq Business::CreditCard::cardtype($data) ) {
                return TRUE;
            }
        }
        return FALSE;
    }
    else {
        return Business::CreditCard::validate($data) ? TRUE : FALSE;
    }
}

1;
__END__

=head1 NAME

FormValidator::Simple::Plugin::CreditCard - credit card number validation

=head1 SYNOPSIS

    use FormValidator::Simple qw/CreditCard/;

    my $q = CGI->new;
    $q->param( number => '5276 4400 6542 1319' );

    my $result = FormValidator::Simple->check( $q => [
        number => [ 'CREDIT_CARD' ],
    ] );

=head1 DESCRIPTION

This modules provides credit card number validation.

See L<Business::CreditCard>

=head1 CARD TYPE CHECK

You can also check card type.

    my $result = FormValidator::Simple->check( $q => [
        number => [ ['CREDIT_CARD', 'VISA', 'MASTER' ] ],
    ] );

In this sample, it returns true if the number is Visa Card or Master Card.
You can choose card type from follow listing.

=over 4

=item VISA

=item MASTER

=item DISCOVER

=item AMEX

=item DINERS

=item ENROUTE

=item JCB

=item BANKCARD

=item SWITCH

=item SOLO

=back

=head1 SEE ALSO

L<FormValidator::Simple>,

L<Business::CreditCard>

=head1 AUTHOR

Lyo Kato E<lt>lyo.kato@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Lyo Kato

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself

=cut
