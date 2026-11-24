package Google::Cloud::Universalledger::V1::Types::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ClientTransaction',
    as InstanceOf['Google::Cloud::Universalledger::V1::Types::ClientTransaction'];

coerce 'ClientTransaction',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Types::ClientTransaction'->new($_) };

declare 'RepeatedClientTransaction',
    as ArrayRef[ClientTransaction()];

coerce 'RepeatedClientTransaction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Types::ClientTransaction'->new($_) } @$_ ] };

declare 'MapStringClientTransaction',
    as HashRef[ClientTransaction()];

declare 'SignedTransaction',
    as InstanceOf['Google::Cloud::Universalledger::V1::Types::SignedTransaction'];

coerce 'SignedTransaction',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Types::SignedTransaction'->new($_) };

declare 'RepeatedSignedTransaction',
    as ArrayRef[SignedTransaction()];

coerce 'RepeatedSignedTransaction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Types::SignedTransaction'->new($_) } @$_ ] };

declare 'MapStringSignedTransaction',
    as HashRef[SignedTransaction()];

declare 'TransactionChain',
    as InstanceOf['Google::Cloud::Universalledger::V1::Types::TransactionChain'];

coerce 'TransactionChain',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Types::TransactionChain'->new($_) };

declare 'RepeatedTransactionChain',
    as ArrayRef[TransactionChain()];

coerce 'RepeatedTransactionChain',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Types::TransactionChain'->new($_) } @$_ ] };

declare 'MapStringTransactionChain',
    as HashRef[TransactionChain()];

declare 'MerkleTree',
    as InstanceOf['Google::Cloud::Universalledger::V1::Types::MerkleTree'];

coerce 'MerkleTree',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Types::MerkleTree'->new($_) };

declare 'RepeatedMerkleTree',
    as ArrayRef[MerkleTree()];

coerce 'RepeatedMerkleTree',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Types::MerkleTree'->new($_) } @$_ ] };

declare 'MapStringMerkleTree',
    as HashRef[MerkleTree()];

declare 'RoundCertificate',
    as InstanceOf['Google::Cloud::Universalledger::V1::Types::RoundCertificate'];

coerce 'RoundCertificate',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Types::RoundCertificate'->new($_) };

declare 'RepeatedRoundCertificate',
    as ArrayRef[RoundCertificate()];

coerce 'RepeatedRoundCertificate',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Types::RoundCertificate'->new($_) } @$_ ] };

declare 'MapStringRoundCertificate',
    as HashRef[RoundCertificate()];

declare 'TransactionEffect',
    as InstanceOf['Google::Cloud::Universalledger::V1::Types::TransactionEffect'];

coerce 'TransactionEffect',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Types::TransactionEffect'->new($_) };

declare 'RepeatedTransactionEffect',
    as ArrayRef[TransactionEffect()];

coerce 'RepeatedTransactionEffect',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Types::TransactionEffect'->new($_) } @$_ ] };

declare 'MapStringTransactionEffect',
    as HashRef[TransactionEffect()];

declare 'TransactionStatus',
    as InstanceOf['Google::Cloud::Universalledger::V1::Types::TransactionStatus'];

coerce 'TransactionStatus',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Types::TransactionStatus'->new($_) };

declare 'RepeatedTransactionStatus',
    as ArrayRef[TransactionStatus()];

coerce 'RepeatedTransactionStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Types::TransactionStatus'->new($_) } @$_ ] };

declare 'MapStringTransactionStatus',
    as HashRef[TransactionStatus()];

declare 'TransactionEffects',
    as InstanceOf['Google::Cloud::Universalledger::V1::Types::TransactionEffects'];

coerce 'TransactionEffects',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Types::TransactionEffects'->new($_) };

declare 'RepeatedTransactionEffects',
    as ArrayRef[TransactionEffects()];

coerce 'RepeatedTransactionEffects',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Types::TransactionEffects'->new($_) } @$_ ] };

declare 'MapStringTransactionEffects',
    as HashRef[TransactionEffects()];

declare 'TransactionEvent',
    as InstanceOf['Google::Cloud::Universalledger::V1::Types::TransactionEvent'];

coerce 'TransactionEvent',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Types::TransactionEvent'->new($_) };

declare 'RepeatedTransactionEvent',
    as ArrayRef[TransactionEvent()];

coerce 'RepeatedTransactionEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Types::TransactionEvent'->new($_) } @$_ ] };

declare 'MapStringTransactionEvent',
    as HashRef[TransactionEvent()];

declare 'EventAttribute',
    as InstanceOf['Google::Cloud::Universalledger::V1::Types::TransactionEvent::EventAttribute'];

coerce 'EventAttribute',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Types::TransactionEvent::EventAttribute'->new($_) };

declare 'RepeatedEventAttribute',
    as ArrayRef[EventAttribute()];

coerce 'RepeatedEventAttribute',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Types::TransactionEvent::EventAttribute'->new($_) } @$_ ] };

declare 'MapStringEventAttribute',
    as HashRef[EventAttribute()];

declare 'TransactionCertificate',
    as InstanceOf['Google::Cloud::Universalledger::V1::Types::TransactionCertificate'];

coerce 'TransactionCertificate',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Types::TransactionCertificate'->new($_) };

declare 'RepeatedTransactionCertificate',
    as ArrayRef[TransactionCertificate()];

coerce 'RepeatedTransactionCertificate',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Types::TransactionCertificate'->new($_) } @$_ ] };

declare 'MapStringTransactionCertificate',
    as HashRef[TransactionCertificate()];

declare 'ProofOfInclusion',
    as InstanceOf['Google::Cloud::Universalledger::V1::Types::ProofOfInclusion'];

coerce 'ProofOfInclusion',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Types::ProofOfInclusion'->new($_) };

declare 'RepeatedProofOfInclusion',
    as ArrayRef[ProofOfInclusion()];

coerce 'RepeatedProofOfInclusion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Types::ProofOfInclusion'->new($_) } @$_ ] };

declare 'MapStringProofOfInclusion',
    as HashRef[ProofOfInclusion()];

declare 'MerkleTreeNode',
    as InstanceOf['Google::Cloud::Universalledger::V1::Types::ProofOfInclusion::MerkleTreeNode'];

coerce 'MerkleTreeNode',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Types::ProofOfInclusion::MerkleTreeNode'->new($_) };

declare 'RepeatedMerkleTreeNode',
    as ArrayRef[MerkleTreeNode()];

coerce 'RepeatedMerkleTreeNode',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Types::ProofOfInclusion::MerkleTreeNode'->new($_) } @$_ ] };

declare 'MapStringMerkleTreeNode',
    as HashRef[MerkleTreeNode()];

declare 'TransactionAttempt',
    as InstanceOf['Google::Cloud::Universalledger::V1::Types::TransactionAttempt'];

coerce 'TransactionAttempt',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Types::TransactionAttempt'->new($_) };

declare 'RepeatedTransactionAttempt',
    as ArrayRef[TransactionAttempt()];

coerce 'RepeatedTransactionAttempt',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Types::TransactionAttempt'->new($_) } @$_ ] };

declare 'MapStringTransactionAttempt',
    as HashRef[TransactionAttempt()];

declare 'TransactionStatus',
    as (Int | Str);

declare 'SignedQueryRequest',
    as InstanceOf['Google::Cloud::Universalledger::V1::Types::SignedQueryRequest'];

coerce 'SignedQueryRequest',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Types::SignedQueryRequest'->new($_) };

declare 'RepeatedSignedQueryRequest',
    as ArrayRef[SignedQueryRequest()];

coerce 'RepeatedSignedQueryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Types::SignedQueryRequest'->new($_) } @$_ ] };

declare 'MapStringSignedQueryRequest',
    as HashRef[SignedQueryRequest()];

declare 'ClientQuery',
    as InstanceOf['Google::Cloud::Universalledger::V1::Types::ClientQuery'];

coerce 'ClientQuery',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Types::ClientQuery'->new($_) };

declare 'RepeatedClientQuery',
    as ArrayRef[ClientQuery()];

coerce 'RepeatedClientQuery',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Types::ClientQuery'->new($_) } @$_ ] };

declare 'MapStringClientQuery',
    as HashRef[ClientQuery()];

declare 'AccountQuery',
    as InstanceOf['Google::Cloud::Universalledger::V1::Types::AccountQuery'];

coerce 'AccountQuery',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Types::AccountQuery'->new($_) };

declare 'RepeatedAccountQuery',
    as ArrayRef[AccountQuery()];

coerce 'RepeatedAccountQuery',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Types::AccountQuery'->new($_) } @$_ ] };

declare 'MapStringAccountQuery',
    as HashRef[AccountQuery()];

declare 'TransactionStateQuery',
    as InstanceOf['Google::Cloud::Universalledger::V1::Types::TransactionStateQuery'];

coerce 'TransactionStateQuery',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Types::TransactionStateQuery'->new($_) };

declare 'RepeatedTransactionStateQuery',
    as ArrayRef[TransactionStateQuery()];

coerce 'RepeatedTransactionStateQuery',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Types::TransactionStateQuery'->new($_) } @$_ ] };

declare 'MapStringTransactionStateQuery',
    as HashRef[TransactionStateQuery()];

declare 'TransactionState',
    as InstanceOf['Google::Cloud::Universalledger::V1::Types::TransactionState'];

coerce 'TransactionState',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Types::TransactionState'->new($_) };

declare 'RepeatedTransactionState',
    as ArrayRef[TransactionState()];

coerce 'RepeatedTransactionState',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Types::TransactionState'->new($_) } @$_ ] };

declare 'MapStringTransactionState',
    as HashRef[TransactionState()];

1;

__END__

=head1 NAME

Google::Cloud::Universalledger::V1::Types::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
