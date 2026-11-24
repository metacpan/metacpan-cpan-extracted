package Google::Cloud::Universalledger::V1::Common::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'NoneValue',
    as (Int | Str);

declare 'KeySlot',
    as (Int | Str);

declare 'CurrencyValue',
    as InstanceOf['Google::Cloud::Universalledger::V1::Common::CurrencyValue'];

coerce 'CurrencyValue',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Common::CurrencyValue'->new($_) };

declare 'RepeatedCurrencyValue',
    as ArrayRef[CurrencyValue()];

coerce 'RepeatedCurrencyValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Common::CurrencyValue'->new($_) } @$_ ] };

declare 'MapStringCurrencyValue',
    as HashRef[CurrencyValue()];

declare 'QualifiedCurrencyValue',
    as InstanceOf['Google::Cloud::Universalledger::V1::Common::QualifiedCurrencyValue'];

coerce 'QualifiedCurrencyValue',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Common::QualifiedCurrencyValue'->new($_) };

declare 'RepeatedQualifiedCurrencyValue',
    as ArrayRef[QualifiedCurrencyValue()];

coerce 'RepeatedQualifiedCurrencyValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Common::QualifiedCurrencyValue'->new($_) } @$_ ] };

declare 'MapStringQualifiedCurrencyValue',
    as HashRef[QualifiedCurrencyValue()];

declare 'AmountValue',
    as InstanceOf['Google::Cloud::Universalledger::V1::Common::AmountValue'];

coerce 'AmountValue',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Common::AmountValue'->new($_) };

declare 'RepeatedAmountValue',
    as ArrayRef[AmountValue()];

coerce 'RepeatedAmountValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Common::AmountValue'->new($_) } @$_ ] };

declare 'MapStringAmountValue',
    as HashRef[AmountValue()];

declare 'StringList',
    as InstanceOf['Google::Cloud::Universalledger::V1::Common::StringList'];

coerce 'StringList',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Common::StringList'->new($_) };

declare 'RepeatedStringList',
    as ArrayRef[StringList()];

coerce 'RepeatedStringList',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Common::StringList'->new($_) } @$_ ] };

declare 'MapStringStringList',
    as HashRef[StringList()];

declare 'Int64List',
    as InstanceOf['Google::Cloud::Universalledger::V1::Common::Int64List'];

coerce 'Int64List',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Common::Int64List'->new($_) };

declare 'RepeatedInt64List',
    as ArrayRef[Int64List()];

coerce 'RepeatedInt64List',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Common::Int64List'->new($_) } @$_ ] };

declare 'MapStringInt64List',
    as HashRef[Int64List()];

declare 'AccountValue',
    as InstanceOf['Google::Cloud::Universalledger::V1::Common::AccountValue'];

coerce 'AccountValue',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Common::AccountValue'->new($_) };

declare 'RepeatedAccountValue',
    as ArrayRef[AccountValue()];

coerce 'RepeatedAccountValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Common::AccountValue'->new($_) } @$_ ] };

declare 'MapStringAccountValue',
    as HashRef[AccountValue()];

declare 'BoolList',
    as InstanceOf['Google::Cloud::Universalledger::V1::Common::BoolList'];

coerce 'BoolList',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Common::BoolList'->new($_) };

declare 'RepeatedBoolList',
    as ArrayRef[BoolList()];

coerce 'RepeatedBoolList',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Common::BoolList'->new($_) } @$_ ] };

declare 'MapStringBoolList',
    as HashRef[BoolList()];

declare 'ContractValue',
    as InstanceOf['Google::Cloud::Universalledger::V1::Common::ContractValue'];

coerce 'ContractValue',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Common::ContractValue'->new($_) };

declare 'RepeatedContractValue',
    as ArrayRef[ContractValue()];

coerce 'RepeatedContractValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Common::ContractValue'->new($_) } @$_ ] };

declare 'MapStringContractValue',
    as HashRef[ContractValue()];

declare 'DictValue',
    as InstanceOf['Google::Cloud::Universalledger::V1::Common::DictValue'];

coerce 'DictValue',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Common::DictValue'->new($_) };

declare 'RepeatedDictValue',
    as ArrayRef[DictValue()];

coerce 'RepeatedDictValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Common::DictValue'->new($_) } @$_ ] };

declare 'MapStringDictValue',
    as HashRef[DictValue()];

declare 'ListValue',
    as InstanceOf['Google::Cloud::Universalledger::V1::Common::ListValue'];

coerce 'ListValue',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Common::ListValue'->new($_) };

declare 'RepeatedListValue',
    as ArrayRef[ListValue()];

coerce 'RepeatedListValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Common::ListValue'->new($_) } @$_ ] };

declare 'MapStringListValue',
    as HashRef[ListValue()];

declare 'RepeatedValue',
    as InstanceOf['Google::Cloud::Universalledger::V1::Common::RepeatedValue'];

coerce 'RepeatedValue',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Common::RepeatedValue'->new($_) };

declare 'RepeatedRepeatedValue',
    as ArrayRef[RepeatedValue()];

coerce 'RepeatedRepeatedValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Common::RepeatedValue'->new($_) } @$_ ] };

declare 'MapStringRepeatedValue',
    as HashRef[RepeatedValue()];

declare 'Value',
    as InstanceOf['Google::Cloud::Universalledger::V1::Common::Value'];

coerce 'Value',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Common::Value'->new($_) };

declare 'RepeatedValue',
    as ArrayRef[Value()];

coerce 'RepeatedValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Common::Value'->new($_) } @$_ ] };

declare 'MapStringValue',
    as HashRef[Value()];

1;

__END__

=head1 NAME

Google::Cloud::Universalledger::V1::Common::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
