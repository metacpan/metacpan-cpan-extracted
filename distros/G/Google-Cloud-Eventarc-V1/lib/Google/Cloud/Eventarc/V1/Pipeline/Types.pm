package Google::Cloud::Eventarc::V1::Pipeline::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Pipeline',
    as InstanceOf['Google::Cloud::Eventarc::V1::Pipeline::Pipeline'];

coerce 'Pipeline',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Pipeline::Pipeline'->new($_) };

declare 'RepeatedPipeline',
    as ArrayRef[Pipeline()];

coerce 'RepeatedPipeline',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Pipeline::Pipeline'->new($_) } @$_ ] };

declare 'MapStringPipeline',
    as HashRef[Pipeline()];

declare 'MessagePayloadFormat',
    as InstanceOf['Google::Cloud::Eventarc::V1::Pipeline::Pipeline::MessagePayloadFormat'];

coerce 'MessagePayloadFormat',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Pipeline::Pipeline::MessagePayloadFormat'->new($_) };

declare 'RepeatedMessagePayloadFormat',
    as ArrayRef[MessagePayloadFormat()];

coerce 'RepeatedMessagePayloadFormat',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Pipeline::Pipeline::MessagePayloadFormat'->new($_) } @$_ ] };

declare 'MapStringMessagePayloadFormat',
    as HashRef[MessagePayloadFormat()];

declare 'JsonFormat',
    as InstanceOf['Google::Cloud::Eventarc::V1::Pipeline::Pipeline::MessagePayloadFormat::JsonFormat'];

coerce 'JsonFormat',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Pipeline::Pipeline::MessagePayloadFormat::JsonFormat'->new($_) };

declare 'RepeatedJsonFormat',
    as ArrayRef[JsonFormat()];

coerce 'RepeatedJsonFormat',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Pipeline::Pipeline::MessagePayloadFormat::JsonFormat'->new($_) } @$_ ] };

declare 'MapStringJsonFormat',
    as HashRef[JsonFormat()];

declare 'ProtobufFormat',
    as InstanceOf['Google::Cloud::Eventarc::V1::Pipeline::Pipeline::MessagePayloadFormat::ProtobufFormat'];

coerce 'ProtobufFormat',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Pipeline::Pipeline::MessagePayloadFormat::ProtobufFormat'->new($_) };

declare 'RepeatedProtobufFormat',
    as ArrayRef[ProtobufFormat()];

coerce 'RepeatedProtobufFormat',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Pipeline::Pipeline::MessagePayloadFormat::ProtobufFormat'->new($_) } @$_ ] };

declare 'MapStringProtobufFormat',
    as HashRef[ProtobufFormat()];

declare 'AvroFormat',
    as InstanceOf['Google::Cloud::Eventarc::V1::Pipeline::Pipeline::MessagePayloadFormat::AvroFormat'];

coerce 'AvroFormat',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Pipeline::Pipeline::MessagePayloadFormat::AvroFormat'->new($_) };

declare 'RepeatedAvroFormat',
    as ArrayRef[AvroFormat()];

coerce 'RepeatedAvroFormat',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Pipeline::Pipeline::MessagePayloadFormat::AvroFormat'->new($_) } @$_ ] };

declare 'MapStringAvroFormat',
    as HashRef[AvroFormat()];

declare 'Destination',
    as InstanceOf['Google::Cloud::Eventarc::V1::Pipeline::Pipeline::Destination'];

coerce 'Destination',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Pipeline::Pipeline::Destination'->new($_) };

declare 'RepeatedDestination',
    as ArrayRef[Destination()];

coerce 'RepeatedDestination',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Pipeline::Pipeline::Destination'->new($_) } @$_ ] };

declare 'MapStringDestination',
    as HashRef[Destination()];

declare 'NetworkConfig',
    as InstanceOf['Google::Cloud::Eventarc::V1::Pipeline::Pipeline::Destination::NetworkConfig'];

coerce 'NetworkConfig',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Pipeline::Pipeline::Destination::NetworkConfig'->new($_) };

declare 'RepeatedNetworkConfig',
    as ArrayRef[NetworkConfig()];

coerce 'RepeatedNetworkConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Pipeline::Pipeline::Destination::NetworkConfig'->new($_) } @$_ ] };

declare 'MapStringNetworkConfig',
    as HashRef[NetworkConfig()];

declare 'HttpEndpoint',
    as InstanceOf['Google::Cloud::Eventarc::V1::Pipeline::Pipeline::Destination::HttpEndpoint'];

coerce 'HttpEndpoint',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Pipeline::Pipeline::Destination::HttpEndpoint'->new($_) };

declare 'RepeatedHttpEndpoint',
    as ArrayRef[HttpEndpoint()];

coerce 'RepeatedHttpEndpoint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Pipeline::Pipeline::Destination::HttpEndpoint'->new($_) } @$_ ] };

declare 'MapStringHttpEndpoint',
    as HashRef[HttpEndpoint()];

declare 'AuthenticationConfig',
    as InstanceOf['Google::Cloud::Eventarc::V1::Pipeline::Pipeline::Destination::AuthenticationConfig'];

coerce 'AuthenticationConfig',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Pipeline::Pipeline::Destination::AuthenticationConfig'->new($_) };

declare 'RepeatedAuthenticationConfig',
    as ArrayRef[AuthenticationConfig()];

coerce 'RepeatedAuthenticationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Pipeline::Pipeline::Destination::AuthenticationConfig'->new($_) } @$_ ] };

declare 'MapStringAuthenticationConfig',
    as HashRef[AuthenticationConfig()];

declare 'OidcToken',
    as InstanceOf['Google::Cloud::Eventarc::V1::Pipeline::Pipeline::Destination::AuthenticationConfig::OidcToken'];

coerce 'OidcToken',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Pipeline::Pipeline::Destination::AuthenticationConfig::OidcToken'->new($_) };

declare 'RepeatedOidcToken',
    as ArrayRef[OidcToken()];

coerce 'RepeatedOidcToken',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Pipeline::Pipeline::Destination::AuthenticationConfig::OidcToken'->new($_) } @$_ ] };

declare 'MapStringOidcToken',
    as HashRef[OidcToken()];

declare 'OAuthToken',
    as InstanceOf['Google::Cloud::Eventarc::V1::Pipeline::Pipeline::Destination::AuthenticationConfig::OAuthToken'];

coerce 'OAuthToken',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Pipeline::Pipeline::Destination::AuthenticationConfig::OAuthToken'->new($_) };

declare 'RepeatedOAuthToken',
    as ArrayRef[OAuthToken()];

coerce 'RepeatedOAuthToken',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Pipeline::Pipeline::Destination::AuthenticationConfig::OAuthToken'->new($_) } @$_ ] };

declare 'MapStringOAuthToken',
    as HashRef[OAuthToken()];

declare 'Mediation',
    as InstanceOf['Google::Cloud::Eventarc::V1::Pipeline::Pipeline::Mediation'];

coerce 'Mediation',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Pipeline::Pipeline::Mediation'->new($_) };

declare 'RepeatedMediation',
    as ArrayRef[Mediation()];

coerce 'RepeatedMediation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Pipeline::Pipeline::Mediation'->new($_) } @$_ ] };

declare 'MapStringMediation',
    as HashRef[Mediation()];

declare 'Transformation',
    as InstanceOf['Google::Cloud::Eventarc::V1::Pipeline::Pipeline::Mediation::Transformation'];

coerce 'Transformation',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Pipeline::Pipeline::Mediation::Transformation'->new($_) };

declare 'RepeatedTransformation',
    as ArrayRef[Transformation()];

coerce 'RepeatedTransformation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Pipeline::Pipeline::Mediation::Transformation'->new($_) } @$_ ] };

declare 'MapStringTransformation',
    as HashRef[Transformation()];

declare 'RetryPolicy',
    as InstanceOf['Google::Cloud::Eventarc::V1::Pipeline::Pipeline::RetryPolicy'];

coerce 'RetryPolicy',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Pipeline::Pipeline::RetryPolicy'->new($_) };

declare 'RepeatedRetryPolicy',
    as ArrayRef[RetryPolicy()];

coerce 'RepeatedRetryPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Pipeline::Pipeline::RetryPolicy'->new($_) } @$_ ] };

declare 'MapStringRetryPolicy',
    as HashRef[RetryPolicy()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Eventarc::V1::Pipeline::Pipeline::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Pipeline::Pipeline::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Pipeline::Pipeline::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'AnnotationsEntry',
    as InstanceOf['Google::Cloud::Eventarc::V1::Pipeline::Pipeline::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Pipeline::Pipeline::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Pipeline::Pipeline::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Eventarc::V1::Pipeline::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
