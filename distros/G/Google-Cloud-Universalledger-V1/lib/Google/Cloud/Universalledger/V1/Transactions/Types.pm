package Google::Cloud::Universalledger::V1::Transactions::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SettlementMode',
    as (Int | Str);

declare 'KeyFormat',
    as (Int | Str);

declare 'SettlementRequest',
    as InstanceOf['Google::Cloud::Universalledger::V1::Transactions::SettlementRequest'];

coerce 'SettlementRequest',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Transactions::SettlementRequest'->new($_) };

declare 'RepeatedSettlementRequest',
    as ArrayRef[SettlementRequest()];

coerce 'RepeatedSettlementRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Transactions::SettlementRequest'->new($_) } @$_ ] };

declare 'MapStringSettlementRequest',
    as HashRef[SettlementRequest()];

declare 'CreateAccount',
    as InstanceOf['Google::Cloud::Universalledger::V1::Transactions::CreateAccount'];

coerce 'CreateAccount',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Transactions::CreateAccount'->new($_) };

declare 'RepeatedCreateAccount',
    as ArrayRef[CreateAccount()];

coerce 'RepeatedCreateAccount',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Transactions::CreateAccount'->new($_) } @$_ ] };

declare 'MapStringCreateAccount',
    as HashRef[CreateAccount()];

declare 'DeactivateAccount',
    as InstanceOf['Google::Cloud::Universalledger::V1::Transactions::DeactivateAccount'];

coerce 'DeactivateAccount',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Transactions::DeactivateAccount'->new($_) };

declare 'RepeatedDeactivateAccount',
    as ArrayRef[DeactivateAccount()];

coerce 'RepeatedDeactivateAccount',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Transactions::DeactivateAccount'->new($_) } @$_ ] };

declare 'MapStringDeactivateAccount',
    as HashRef[DeactivateAccount()];

declare 'ActivateAccount',
    as InstanceOf['Google::Cloud::Universalledger::V1::Transactions::ActivateAccount'];

coerce 'ActivateAccount',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Transactions::ActivateAccount'->new($_) };

declare 'RepeatedActivateAccount',
    as ArrayRef[ActivateAccount()];

coerce 'RepeatedActivateAccount',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Transactions::ActivateAccount'->new($_) } @$_ ] };

declare 'MapStringActivateAccount',
    as HashRef[ActivateAccount()];

declare 'AddRoles',
    as InstanceOf['Google::Cloud::Universalledger::V1::Transactions::AddRoles'];

coerce 'AddRoles',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Transactions::AddRoles'->new($_) };

declare 'RepeatedAddRoles',
    as ArrayRef[AddRoles()];

coerce 'RepeatedAddRoles',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Transactions::AddRoles'->new($_) } @$_ ] };

declare 'MapStringAddRoles',
    as HashRef[AddRoles()];

declare 'RemoveRoles',
    as InstanceOf['Google::Cloud::Universalledger::V1::Transactions::RemoveRoles'];

coerce 'RemoveRoles',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Transactions::RemoveRoles'->new($_) };

declare 'RepeatedRemoveRoles',
    as ArrayRef[RemoveRoles()];

coerce 'RepeatedRemoveRoles',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Transactions::RemoveRoles'->new($_) } @$_ ] };

declare 'MapStringRemoveRoles',
    as HashRef[RemoveRoles()];

declare 'ChangeAccountManager',
    as InstanceOf['Google::Cloud::Universalledger::V1::Transactions::ChangeAccountManager'];

coerce 'ChangeAccountManager',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Transactions::ChangeAccountManager'->new($_) };

declare 'RepeatedChangeAccountManager',
    as ArrayRef[ChangeAccountManager()];

coerce 'RepeatedChangeAccountManager',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Transactions::ChangeAccountManager'->new($_) } @$_ ] };

declare 'MapStringChangeAccountManager',
    as HashRef[ChangeAccountManager()];

declare 'IncreaseTokenIssuanceLimit',
    as InstanceOf['Google::Cloud::Universalledger::V1::Transactions::IncreaseTokenIssuanceLimit'];

coerce 'IncreaseTokenIssuanceLimit',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Transactions::IncreaseTokenIssuanceLimit'->new($_) };

declare 'RepeatedIncreaseTokenIssuanceLimit',
    as ArrayRef[IncreaseTokenIssuanceLimit()];

coerce 'RepeatedIncreaseTokenIssuanceLimit',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Transactions::IncreaseTokenIssuanceLimit'->new($_) } @$_ ] };

declare 'MapStringIncreaseTokenIssuanceLimit',
    as HashRef[IncreaseTokenIssuanceLimit()];

declare 'DecreaseTokenIssuanceLimit',
    as InstanceOf['Google::Cloud::Universalledger::V1::Transactions::DecreaseTokenIssuanceLimit'];

coerce 'DecreaseTokenIssuanceLimit',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Transactions::DecreaseTokenIssuanceLimit'->new($_) };

declare 'RepeatedDecreaseTokenIssuanceLimit',
    as ArrayRef[DecreaseTokenIssuanceLimit()];

coerce 'RepeatedDecreaseTokenIssuanceLimit',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Transactions::DecreaseTokenIssuanceLimit'->new($_) } @$_ ] };

declare 'MapStringDecreaseTokenIssuanceLimit',
    as HashRef[DecreaseTokenIssuanceLimit()];

declare 'Mint',
    as InstanceOf['Google::Cloud::Universalledger::V1::Transactions::Mint'];

coerce 'Mint',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Transactions::Mint'->new($_) };

declare 'RepeatedMint',
    as ArrayRef[Mint()];

coerce 'RepeatedMint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Transactions::Mint'->new($_) } @$_ ] };

declare 'MapStringMint',
    as HashRef[Mint()];

declare 'Burn',
    as InstanceOf['Google::Cloud::Universalledger::V1::Transactions::Burn'];

coerce 'Burn',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Transactions::Burn'->new($_) };

declare 'RepeatedBurn',
    as ArrayRef[Burn()];

coerce 'RepeatedBurn',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Transactions::Burn'->new($_) } @$_ ] };

declare 'MapStringBurn',
    as HashRef[Burn()];

declare 'Transfer',
    as InstanceOf['Google::Cloud::Universalledger::V1::Transactions::Transfer'];

coerce 'Transfer',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Transactions::Transfer'->new($_) };

declare 'RepeatedTransfer',
    as ArrayRef[Transfer()];

coerce 'RepeatedTransfer',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Transactions::Transfer'->new($_) } @$_ ] };

declare 'MapStringTransfer',
    as HashRef[Transfer()];

declare 'CreateTokenManager',
    as InstanceOf['Google::Cloud::Universalledger::V1::Transactions::CreateTokenManager'];

coerce 'CreateTokenManager',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Transactions::CreateTokenManager'->new($_) };

declare 'RepeatedCreateTokenManager',
    as ArrayRef[CreateTokenManager()];

coerce 'RepeatedCreateTokenManager',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Transactions::CreateTokenManager'->new($_) } @$_ ] };

declare 'MapStringCreateTokenManager',
    as HashRef[CreateTokenManager()];

declare 'CreateAccountManager',
    as InstanceOf['Google::Cloud::Universalledger::V1::Transactions::CreateAccountManager'];

coerce 'CreateAccountManager',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Transactions::CreateAccountManager'->new($_) };

declare 'RepeatedCreateAccountManager',
    as ArrayRef[CreateAccountManager()];

coerce 'RepeatedCreateAccountManager',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Transactions::CreateAccountManager'->new($_) } @$_ ] };

declare 'MapStringCreateAccountManager',
    as HashRef[CreateAccountManager()];

declare 'CreateClearinghouse',
    as InstanceOf['Google::Cloud::Universalledger::V1::Transactions::CreateClearinghouse'];

coerce 'CreateClearinghouse',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Transactions::CreateClearinghouse'->new($_) };

declare 'RepeatedCreateClearinghouse',
    as ArrayRef[CreateClearinghouse()];

coerce 'RepeatedCreateClearinghouse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Transactions::CreateClearinghouse'->new($_) } @$_ ] };

declare 'MapStringCreateClearinghouse',
    as HashRef[CreateClearinghouse()];

declare 'TransferPlatformOperator',
    as InstanceOf['Google::Cloud::Universalledger::V1::Transactions::TransferPlatformOperator'];

coerce 'TransferPlatformOperator',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Transactions::TransferPlatformOperator'->new($_) };

declare 'RepeatedTransferPlatformOperator',
    as ArrayRef[TransferPlatformOperator()];

coerce 'RepeatedTransferPlatformOperator',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Transactions::TransferPlatformOperator'->new($_) } @$_ ] };

declare 'MapStringTransferPlatformOperator',
    as HashRef[TransferPlatformOperator()];

declare 'CreateCurrencyOperator',
    as InstanceOf['Google::Cloud::Universalledger::V1::Transactions::CreateCurrencyOperator'];

coerce 'CreateCurrencyOperator',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Transactions::CreateCurrencyOperator'->new($_) };

declare 'RepeatedCreateCurrencyOperator',
    as ArrayRef[CreateCurrencyOperator()];

coerce 'RepeatedCreateCurrencyOperator',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Transactions::CreateCurrencyOperator'->new($_) } @$_ ] };

declare 'MapStringCreateCurrencyOperator',
    as HashRef[CreateCurrencyOperator()];

declare 'TransferCurrencyOperator',
    as InstanceOf['Google::Cloud::Universalledger::V1::Transactions::TransferCurrencyOperator'];

coerce 'TransferCurrencyOperator',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Transactions::TransferCurrencyOperator'->new($_) };

declare 'RepeatedTransferCurrencyOperator',
    as ArrayRef[TransferCurrencyOperator()];

coerce 'RepeatedTransferCurrencyOperator',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Transactions::TransferCurrencyOperator'->new($_) } @$_ ] };

declare 'MapStringTransferCurrencyOperator',
    as HashRef[TransferCurrencyOperator()];

declare 'CreateSnapshot',
    as InstanceOf['Google::Cloud::Universalledger::V1::Transactions::CreateSnapshot'];

coerce 'CreateSnapshot',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Transactions::CreateSnapshot'->new($_) };

declare 'RepeatedCreateSnapshot',
    as ArrayRef[CreateSnapshot()];

coerce 'RepeatedCreateSnapshot',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Transactions::CreateSnapshot'->new($_) } @$_ ] };

declare 'MapStringCreateSnapshot',
    as HashRef[CreateSnapshot()];

declare 'CreateContract',
    as InstanceOf['Google::Cloud::Universalledger::V1::Transactions::CreateContract'];

coerce 'CreateContract',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Transactions::CreateContract'->new($_) };

declare 'RepeatedCreateContract',
    as ArrayRef[CreateContract()];

coerce 'RepeatedCreateContract',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Transactions::CreateContract'->new($_) } @$_ ] };

declare 'MapStringCreateContract',
    as HashRef[CreateContract()];

declare 'InitArgumentsEntry',
    as InstanceOf['Google::Cloud::Universalledger::V1::Transactions::CreateContract::InitArgumentsEntry'];

coerce 'InitArgumentsEntry',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Transactions::CreateContract::InitArgumentsEntry'->new($_) };

declare 'RepeatedInitArgumentsEntry',
    as ArrayRef[InitArgumentsEntry()];

coerce 'RepeatedInitArgumentsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Transactions::CreateContract::InitArgumentsEntry'->new($_) } @$_ ] };

declare 'MapStringInitArgumentsEntry',
    as HashRef[InitArgumentsEntry()];

declare 'GrantContractPermissions',
    as InstanceOf['Google::Cloud::Universalledger::V1::Transactions::GrantContractPermissions'];

coerce 'GrantContractPermissions',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Transactions::GrantContractPermissions'->new($_) };

declare 'RepeatedGrantContractPermissions',
    as ArrayRef[GrantContractPermissions()];

coerce 'RepeatedGrantContractPermissions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Transactions::GrantContractPermissions'->new($_) } @$_ ] };

declare 'MapStringGrantContractPermissions',
    as HashRef[GrantContractPermissions()];

declare 'InvokeContractMethod',
    as InstanceOf['Google::Cloud::Universalledger::V1::Transactions::InvokeContractMethod'];

coerce 'InvokeContractMethod',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Transactions::InvokeContractMethod'->new($_) };

declare 'RepeatedInvokeContractMethod',
    as ArrayRef[InvokeContractMethod()];

coerce 'RepeatedInvokeContractMethod',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Transactions::InvokeContractMethod'->new($_) } @$_ ] };

declare 'MapStringInvokeContractMethod',
    as HashRef[InvokeContractMethod()];

declare 'MethodArgumentsEntry',
    as InstanceOf['Google::Cloud::Universalledger::V1::Transactions::InvokeContractMethod::MethodArgumentsEntry'];

coerce 'MethodArgumentsEntry',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Transactions::InvokeContractMethod::MethodArgumentsEntry'->new($_) };

declare 'RepeatedMethodArgumentsEntry',
    as ArrayRef[MethodArgumentsEntry()];

coerce 'RepeatedMethodArgumentsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Transactions::InvokeContractMethod::MethodArgumentsEntry'->new($_) } @$_ ] };

declare 'MapStringMethodArgumentsEntry',
    as HashRef[MethodArgumentsEntry()];

declare 'CreateContractTokenManager',
    as InstanceOf['Google::Cloud::Universalledger::V1::Transactions::CreateContractTokenManager'];

coerce 'CreateContractTokenManager',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Transactions::CreateContractTokenManager'->new($_) };

declare 'RepeatedCreateContractTokenManager',
    as ArrayRef[CreateContractTokenManager()];

coerce 'RepeatedCreateContractTokenManager',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Transactions::CreateContractTokenManager'->new($_) } @$_ ] };

declare 'MapStringCreateContractTokenManager',
    as HashRef[CreateContractTokenManager()];

declare 'TransferContractTokenManager',
    as InstanceOf['Google::Cloud::Universalledger::V1::Transactions::TransferContractTokenManager'];

coerce 'TransferContractTokenManager',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Transactions::TransferContractTokenManager'->new($_) };

declare 'RepeatedTransferContractTokenManager',
    as ArrayRef[TransferContractTokenManager()];

coerce 'RepeatedTransferContractTokenManager',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Transactions::TransferContractTokenManager'->new($_) } @$_ ] };

declare 'MapStringTransferContractTokenManager',
    as HashRef[TransferContractTokenManager()];

declare 'RemoveSigningPublicKey',
    as InstanceOf['Google::Cloud::Universalledger::V1::Transactions::RemoveSigningPublicKey'];

coerce 'RemoveSigningPublicKey',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Transactions::RemoveSigningPublicKey'->new($_) };

declare 'RepeatedRemoveSigningPublicKey',
    as ArrayRef[RemoveSigningPublicKey()];

coerce 'RepeatedRemoveSigningPublicKey',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Transactions::RemoveSigningPublicKey'->new($_) } @$_ ] };

declare 'MapStringRemoveSigningPublicKey',
    as HashRef[RemoveSigningPublicKey()];

declare 'ReplaceSigningPublicKey',
    as InstanceOf['Google::Cloud::Universalledger::V1::Transactions::ReplaceSigningPublicKey'];

coerce 'ReplaceSigningPublicKey',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Transactions::ReplaceSigningPublicKey'->new($_) };

declare 'RepeatedReplaceSigningPublicKey',
    as ArrayRef[ReplaceSigningPublicKey()];

coerce 'RepeatedReplaceSigningPublicKey',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Transactions::ReplaceSigningPublicKey'->new($_) } @$_ ] };

declare 'MapStringReplaceSigningPublicKey',
    as HashRef[ReplaceSigningPublicKey()];

1;

__END__

=head1 NAME

Google::Cloud::Universalledger::V1::Transactions::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
