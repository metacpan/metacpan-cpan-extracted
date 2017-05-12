package Microsoft::AdCenter::V6::NotificationManagementService::AccountSignupPaymentReceiptNotification;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Microsoft::AdCenter::V6::NotificationManagementService::Notification/;

=head1 NAME

Microsoft::AdCenter::V6::NotificationManagementService::AccountSignupPaymentReceiptNotification - Represents "AccountSignupPaymentReceiptNotification" in Microsoft AdCenter Notification Management Service.

=head1 INHERITANCE

Microsoft::AdCenter::V6::NotificationManagementService::Notification

=cut

sub _type_name {
    return 'AccountSignupPaymentReceiptNotification';
}

sub _namespace_uri {
    return 'http://adcenter.microsoft.com/syncapis';
}

our @_attributes = (qw/
    AccountId
    AccountName
    AccountNumber
    AccountSetupFee
    CreditCardLastFour
    CreditCardName
    CreditCardTypeName
    PreferredCurrencyCode
    PreferredUserName
/);

sub _attributes {
    my $self = shift;
    return ($self->SUPER::_attributes, @_attributes);
}

our %_attribute_type = (
    AccountId => 'int',
    AccountName => 'string',
    AccountNumber => 'string',
    AccountSetupFee => 'double',
    CreditCardLastFour => 'string',
    CreditCardName => 'string',
    CreditCardTypeName => 'string',
    PreferredCurrencyCode => 'string',
    PreferredUserName => 'string',
);

sub _attribute_type {
    my ($self, $attribute) = @_;
    if (exists $_attribute_type{$attribute}) {
        return $_attribute_type{$attribute};
    }
    return $self->SUPER::_attribute_type($attribute);
}

our %_attribute_min_occurs = (
    AccountId => 1,
    AccountName => 0,
    AccountNumber => 0,
    AccountSetupFee => 1,
    CreditCardLastFour => 0,
    CreditCardName => 0,
    CreditCardTypeName => 0,
    PreferredCurrencyCode => 0,
    PreferredUserName => 0,
);

sub _attribute_min_occurs {
    my ($self, $attribute) = @_;
    if (exists $_attribute_min_occurs{$attribute}) {
        return $_attribute_min_occurs{$attribute};
    }
    return $self->SUPER::_attribute_min_occurs($attribute);
}

__PACKAGE__->mk_accessors(@_attributes);

1;

=head1 SYNOPSIS

See L<http://msdn.microsoft.com/en-us/library/ee730327.aspx> for documentation of the various data objects.

=cut

=head1 METHODS

Remark: Inherited methods are not listed.

=head2 new

Creates a new instance

=head2 AccountId

Gets/sets AccountId (int)

=head2 AccountName

Gets/sets AccountName (string)

=head2 AccountNumber

Gets/sets AccountNumber (string)

=head2 AccountSetupFee

Gets/sets AccountSetupFee (double)

=head2 CreditCardLastFour

Gets/sets CreditCardLastFour (string)

=head2 CreditCardName

Gets/sets CreditCardName (string)

=head2 CreditCardTypeName

Gets/sets CreditCardTypeName (string)

=head2 PreferredCurrencyCode

Gets/sets PreferredCurrencyCode (string)

=head2 PreferredUserName

Gets/sets PreferredUserName (string)

=cut

