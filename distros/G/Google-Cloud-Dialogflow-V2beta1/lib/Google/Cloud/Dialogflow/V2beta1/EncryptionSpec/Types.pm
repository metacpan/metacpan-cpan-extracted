package Google::Cloud::Dialogflow::V2beta1::EncryptionSpec::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GetEncryptionSpecRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::EncryptionSpec::GetEncryptionSpecRequest'];

coerce 'GetEncryptionSpecRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::EncryptionSpec::GetEncryptionSpecRequest'->new($_) };

declare 'RepeatedGetEncryptionSpecRequest',
    as ArrayRef[GetEncryptionSpecRequest()];

coerce 'RepeatedGetEncryptionSpecRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::EncryptionSpec::GetEncryptionSpecRequest'->new($_) } @$_ ] };

declare 'MapStringGetEncryptionSpecRequest',
    as HashRef[GetEncryptionSpecRequest()];

declare 'EncryptionSpec',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::EncryptionSpec::EncryptionSpec'];

coerce 'EncryptionSpec',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::EncryptionSpec::EncryptionSpec'->new($_) };

declare 'RepeatedEncryptionSpec',
    as ArrayRef[EncryptionSpec()];

coerce 'RepeatedEncryptionSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::EncryptionSpec::EncryptionSpec'->new($_) } @$_ ] };

declare 'MapStringEncryptionSpec',
    as HashRef[EncryptionSpec()];

declare 'InitializeEncryptionSpecRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::EncryptionSpec::InitializeEncryptionSpecRequest'];

coerce 'InitializeEncryptionSpecRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::EncryptionSpec::InitializeEncryptionSpecRequest'->new($_) };

declare 'RepeatedInitializeEncryptionSpecRequest',
    as ArrayRef[InitializeEncryptionSpecRequest()];

coerce 'RepeatedInitializeEncryptionSpecRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::EncryptionSpec::InitializeEncryptionSpecRequest'->new($_) } @$_ ] };

declare 'MapStringInitializeEncryptionSpecRequest',
    as HashRef[InitializeEncryptionSpecRequest()];

declare 'InitializeEncryptionSpecResponse',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::EncryptionSpec::InitializeEncryptionSpecResponse'];

coerce 'InitializeEncryptionSpecResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::EncryptionSpec::InitializeEncryptionSpecResponse'->new($_) };

declare 'RepeatedInitializeEncryptionSpecResponse',
    as ArrayRef[InitializeEncryptionSpecResponse()];

coerce 'RepeatedInitializeEncryptionSpecResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::EncryptionSpec::InitializeEncryptionSpecResponse'->new($_) } @$_ ] };

declare 'MapStringInitializeEncryptionSpecResponse',
    as HashRef[InitializeEncryptionSpecResponse()];

declare 'InitializeEncryptionSpecMetadata',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::EncryptionSpec::InitializeEncryptionSpecMetadata'];

coerce 'InitializeEncryptionSpecMetadata',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::EncryptionSpec::InitializeEncryptionSpecMetadata'->new($_) };

declare 'RepeatedInitializeEncryptionSpecMetadata',
    as ArrayRef[InitializeEncryptionSpecMetadata()];

coerce 'RepeatedInitializeEncryptionSpecMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::EncryptionSpec::InitializeEncryptionSpecMetadata'->new($_) } @$_ ] };

declare 'MapStringInitializeEncryptionSpecMetadata',
    as HashRef[InitializeEncryptionSpecMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Dialogflow::V2beta1::EncryptionSpec::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
