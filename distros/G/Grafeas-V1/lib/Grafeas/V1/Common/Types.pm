package Grafeas::V1::Common::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'NoteKind',
    as (Int | Str);

declare 'RelatedUrl',
    as InstanceOf['Grafeas::V1::Common::RelatedUrl'];

coerce 'RelatedUrl',
    from HashRef, via { 'Grafeas::V1::Common::RelatedUrl'->new($_) };

declare 'RepeatedRelatedUrl',
    as ArrayRef[RelatedUrl()];

coerce 'RepeatedRelatedUrl',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Common::RelatedUrl'->new($_) } @$_ ] };

declare 'MapStringRelatedUrl',
    as HashRef[RelatedUrl()];

declare 'Signature',
    as InstanceOf['Grafeas::V1::Common::Signature'];

coerce 'Signature',
    from HashRef, via { 'Grafeas::V1::Common::Signature'->new($_) };

declare 'RepeatedSignature',
    as ArrayRef[Signature()];

coerce 'RepeatedSignature',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Common::Signature'->new($_) } @$_ ] };

declare 'MapStringSignature',
    as HashRef[Signature()];

declare 'Envelope',
    as InstanceOf['Grafeas::V1::Common::Envelope'];

coerce 'Envelope',
    from HashRef, via { 'Grafeas::V1::Common::Envelope'->new($_) };

declare 'RepeatedEnvelope',
    as ArrayRef[Envelope()];

coerce 'RepeatedEnvelope',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Common::Envelope'->new($_) } @$_ ] };

declare 'MapStringEnvelope',
    as HashRef[Envelope()];

declare 'EnvelopeSignature',
    as InstanceOf['Grafeas::V1::Common::EnvelopeSignature'];

coerce 'EnvelopeSignature',
    from HashRef, via { 'Grafeas::V1::Common::EnvelopeSignature'->new($_) };

declare 'RepeatedEnvelopeSignature',
    as ArrayRef[EnvelopeSignature()];

coerce 'RepeatedEnvelopeSignature',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Common::EnvelopeSignature'->new($_) } @$_ ] };

declare 'MapStringEnvelopeSignature',
    as HashRef[EnvelopeSignature()];

declare 'FileLocation',
    as InstanceOf['Grafeas::V1::Common::FileLocation'];

coerce 'FileLocation',
    from HashRef, via { 'Grafeas::V1::Common::FileLocation'->new($_) };

declare 'RepeatedFileLocation',
    as ArrayRef[FileLocation()];

coerce 'RepeatedFileLocation',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Common::FileLocation'->new($_) } @$_ ] };

declare 'MapStringFileLocation',
    as HashRef[FileLocation()];

declare 'BaseImage',
    as InstanceOf['Grafeas::V1::Common::BaseImage'];

coerce 'BaseImage',
    from HashRef, via { 'Grafeas::V1::Common::BaseImage'->new($_) };

declare 'RepeatedBaseImage',
    as ArrayRef[BaseImage()];

coerce 'RepeatedBaseImage',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Common::BaseImage'->new($_) } @$_ ] };

declare 'MapStringBaseImage',
    as HashRef[BaseImage()];

declare 'LayerDetails',
    as InstanceOf['Grafeas::V1::Common::LayerDetails'];

coerce 'LayerDetails',
    from HashRef, via { 'Grafeas::V1::Common::LayerDetails'->new($_) };

declare 'RepeatedLayerDetails',
    as ArrayRef[LayerDetails()];

coerce 'RepeatedLayerDetails',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Common::LayerDetails'->new($_) } @$_ ] };

declare 'MapStringLayerDetails',
    as HashRef[LayerDetails()];

declare 'License',
    as InstanceOf['Grafeas::V1::Common::License'];

coerce 'License',
    from HashRef, via { 'Grafeas::V1::Common::License'->new($_) };

declare 'RepeatedLicense',
    as ArrayRef[License()];

coerce 'RepeatedLicense',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Common::License'->new($_) } @$_ ] };

declare 'MapStringLicense',
    as HashRef[License()];

declare 'Digest',
    as InstanceOf['Grafeas::V1::Common::Digest'];

coerce 'Digest',
    from HashRef, via { 'Grafeas::V1::Common::Digest'->new($_) };

declare 'RepeatedDigest',
    as ArrayRef[Digest()];

coerce 'RepeatedDigest',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Common::Digest'->new($_) } @$_ ] };

declare 'MapStringDigest',
    as HashRef[Digest()];

1;

__END__

=head1 NAME

Grafeas::V1::Common::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
