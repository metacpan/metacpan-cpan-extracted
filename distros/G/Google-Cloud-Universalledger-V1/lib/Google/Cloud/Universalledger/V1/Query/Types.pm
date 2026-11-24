package Google::Cloud::Universalledger::V1::Query::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Account',
    as InstanceOf['Google::Cloud::Universalledger::V1::Query::Account'];

coerce 'Account',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Query::Account'->new($_) };

declare 'RepeatedAccount',
    as ArrayRef[Account()];

coerce 'RepeatedAccount',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Query::Account'->new($_) } @$_ ] };

declare 'MapStringAccount',
    as HashRef[Account()];

declare 'AccountManagerDetails',
    as InstanceOf['Google::Cloud::Universalledger::V1::Query::AccountManagerDetails'];

coerce 'AccountManagerDetails',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Query::AccountManagerDetails'->new($_) };

declare 'RepeatedAccountManagerDetails',
    as ArrayRef[AccountManagerDetails()];

coerce 'RepeatedAccountManagerDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Query::AccountManagerDetails'->new($_) } @$_ ] };

declare 'MapStringAccountManagerDetails',
    as HashRef[AccountManagerDetails()];

declare 'TokenManagerDetails',
    as InstanceOf['Google::Cloud::Universalledger::V1::Query::TokenManagerDetails'];

coerce 'TokenManagerDetails',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Query::TokenManagerDetails'->new($_) };

declare 'RepeatedTokenManagerDetails',
    as ArrayRef[TokenManagerDetails()];

coerce 'RepeatedTokenManagerDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Query::TokenManagerDetails'->new($_) } @$_ ] };

declare 'MapStringTokenManagerDetails',
    as HashRef[TokenManagerDetails()];

declare 'ContractTokenManagerDetails',
    as InstanceOf['Google::Cloud::Universalledger::V1::Query::ContractTokenManagerDetails'];

coerce 'ContractTokenManagerDetails',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Query::ContractTokenManagerDetails'->new($_) };

declare 'RepeatedContractTokenManagerDetails',
    as ArrayRef[ContractTokenManagerDetails()];

coerce 'RepeatedContractTokenManagerDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Query::ContractTokenManagerDetails'->new($_) } @$_ ] };

declare 'MapStringContractTokenManagerDetails',
    as HashRef[ContractTokenManagerDetails()];

declare 'UserDetails',
    as InstanceOf['Google::Cloud::Universalledger::V1::Query::UserDetails'];

coerce 'UserDetails',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Query::UserDetails'->new($_) };

declare 'RepeatedUserDetails',
    as ArrayRef[UserDetails()];

coerce 'RepeatedUserDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Query::UserDetails'->new($_) } @$_ ] };

declare 'MapStringUserDetails',
    as HashRef[UserDetails()];

declare 'ContractAccountFieldsEntry',
    as InstanceOf['Google::Cloud::Universalledger::V1::Query::UserDetails::ContractAccountFieldsEntry'];

coerce 'ContractAccountFieldsEntry',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Query::UserDetails::ContractAccountFieldsEntry'->new($_) };

declare 'RepeatedContractAccountFieldsEntry',
    as ArrayRef[ContractAccountFieldsEntry()];

coerce 'RepeatedContractAccountFieldsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Query::UserDetails::ContractAccountFieldsEntry'->new($_) } @$_ ] };

declare 'MapStringContractAccountFieldsEntry',
    as HashRef[ContractAccountFieldsEntry()];

declare 'CurrencyOperatorDetails',
    as InstanceOf['Google::Cloud::Universalledger::V1::Query::CurrencyOperatorDetails'];

coerce 'CurrencyOperatorDetails',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Query::CurrencyOperatorDetails'->new($_) };

declare 'RepeatedCurrencyOperatorDetails',
    as ArrayRef[CurrencyOperatorDetails()];

coerce 'RepeatedCurrencyOperatorDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Query::CurrencyOperatorDetails'->new($_) } @$_ ] };

declare 'MapStringCurrencyOperatorDetails',
    as HashRef[CurrencyOperatorDetails()];

declare 'PlatformOperatorDetails',
    as InstanceOf['Google::Cloud::Universalledger::V1::Query::PlatformOperatorDetails'];

coerce 'PlatformOperatorDetails',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Query::PlatformOperatorDetails'->new($_) };

declare 'RepeatedPlatformOperatorDetails',
    as ArrayRef[PlatformOperatorDetails()];

coerce 'RepeatedPlatformOperatorDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Query::PlatformOperatorDetails'->new($_) } @$_ ] };

declare 'MapStringPlatformOperatorDetails',
    as HashRef[PlatformOperatorDetails()];

declare 'ClearingHouseDetails',
    as InstanceOf['Google::Cloud::Universalledger::V1::Query::ClearingHouseDetails'];

coerce 'ClearingHouseDetails',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Query::ClearingHouseDetails'->new($_) };

declare 'RepeatedClearingHouseDetails',
    as ArrayRef[ClearingHouseDetails()];

coerce 'RepeatedClearingHouseDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Query::ClearingHouseDetails'->new($_) } @$_ ] };

declare 'MapStringClearingHouseDetails',
    as HashRef[ClearingHouseDetails()];

declare 'ContractDetails',
    as InstanceOf['Google::Cloud::Universalledger::V1::Query::ContractDetails'];

coerce 'ContractDetails',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Query::ContractDetails'->new($_) };

declare 'RepeatedContractDetails',
    as ArrayRef[ContractDetails()];

coerce 'RepeatedContractDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Query::ContractDetails'->new($_) } @$_ ] };

declare 'MapStringContractDetails',
    as HashRef[ContractDetails()];

declare 'CurrencyBalancesEntry',
    as InstanceOf['Google::Cloud::Universalledger::V1::Query::ContractDetails::CurrencyBalancesEntry'];

coerce 'CurrencyBalancesEntry',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Query::ContractDetails::CurrencyBalancesEntry'->new($_) };

declare 'RepeatedCurrencyBalancesEntry',
    as ArrayRef[CurrencyBalancesEntry()];

coerce 'RepeatedCurrencyBalancesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Query::ContractDetails::CurrencyBalancesEntry'->new($_) } @$_ ] };

declare 'MapStringCurrencyBalancesEntry',
    as HashRef[CurrencyBalancesEntry()];

declare 'BalanceToSettle',
    as InstanceOf['Google::Cloud::Universalledger::V1::Query::BalanceToSettle'];

coerce 'BalanceToSettle',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Query::BalanceToSettle'->new($_) };

declare 'RepeatedBalanceToSettle',
    as ArrayRef[BalanceToSettle()];

coerce 'RepeatedBalanceToSettle',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Query::BalanceToSettle'->new($_) } @$_ ] };

declare 'MapStringBalanceToSettle',
    as HashRef[BalanceToSettle()];

declare 'Fields',
    as InstanceOf['Google::Cloud::Universalledger::V1::Query::Fields'];

coerce 'Fields',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Query::Fields'->new($_) };

declare 'RepeatedFields',
    as ArrayRef[Fields()];

coerce 'RepeatedFields',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Query::Fields'->new($_) } @$_ ] };

declare 'MapStringFields',
    as HashRef[Fields()];

declare 'FieldsEntry',
    as InstanceOf['Google::Cloud::Universalledger::V1::Query::Fields::FieldsEntry'];

coerce 'FieldsEntry',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Query::Fields::FieldsEntry'->new($_) };

declare 'RepeatedFieldsEntry',
    as ArrayRef[FieldsEntry()];

coerce 'RepeatedFieldsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Query::Fields::FieldsEntry'->new($_) } @$_ ] };

declare 'MapStringFieldsEntry',
    as HashRef[FieldsEntry()];

declare 'RedactedField',
    as InstanceOf['Google::Cloud::Universalledger::V1::Query::RedactedField'];

coerce 'RedactedField',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Query::RedactedField'->new($_) };

declare 'RepeatedRedactedField',
    as ArrayRef[RedactedField()];

coerce 'RepeatedRedactedField',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Query::RedactedField'->new($_) } @$_ ] };

declare 'MapStringRedactedField',
    as HashRef[RedactedField()];

1;

__END__

=head1 NAME

Google::Cloud::Universalledger::V1::Query::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
