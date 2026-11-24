package Google::Appengine::V1::AppYaml::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AuthFailAction',
    as (Int | Str);

declare 'LoginRequirement',
    as (Int | Str);

declare 'SecurityLevel',
    as (Int | Str);

declare 'ApiConfigHandler',
    as InstanceOf['Google::Appengine::V1::AppYaml::ApiConfigHandler'];

coerce 'ApiConfigHandler',
    from HashRef, via { 'Google::Appengine::V1::AppYaml::ApiConfigHandler'->new($_) };

declare 'RepeatedApiConfigHandler',
    as ArrayRef[ApiConfigHandler()];

coerce 'RepeatedApiConfigHandler',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1::AppYaml::ApiConfigHandler'->new($_) } @$_ ] };

declare 'MapStringApiConfigHandler',
    as HashRef[ApiConfigHandler()];

declare 'ErrorHandler',
    as InstanceOf['Google::Appengine::V1::AppYaml::ErrorHandler'];

coerce 'ErrorHandler',
    from HashRef, via { 'Google::Appengine::V1::AppYaml::ErrorHandler'->new($_) };

declare 'RepeatedErrorHandler',
    as ArrayRef[ErrorHandler()];

coerce 'RepeatedErrorHandler',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1::AppYaml::ErrorHandler'->new($_) } @$_ ] };

declare 'MapStringErrorHandler',
    as HashRef[ErrorHandler()];

declare 'ErrorCode',
    as (Int | Str);

declare 'UrlMap',
    as InstanceOf['Google::Appengine::V1::AppYaml::UrlMap'];

coerce 'UrlMap',
    from HashRef, via { 'Google::Appengine::V1::AppYaml::UrlMap'->new($_) };

declare 'RepeatedUrlMap',
    as ArrayRef[UrlMap()];

coerce 'RepeatedUrlMap',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1::AppYaml::UrlMap'->new($_) } @$_ ] };

declare 'MapStringUrlMap',
    as HashRef[UrlMap()];

declare 'RedirectHttpResponseCode',
    as (Int | Str);

declare 'StaticFilesHandler',
    as InstanceOf['Google::Appengine::V1::AppYaml::StaticFilesHandler'];

coerce 'StaticFilesHandler',
    from HashRef, via { 'Google::Appengine::V1::AppYaml::StaticFilesHandler'->new($_) };

declare 'RepeatedStaticFilesHandler',
    as ArrayRef[StaticFilesHandler()];

coerce 'RepeatedStaticFilesHandler',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1::AppYaml::StaticFilesHandler'->new($_) } @$_ ] };

declare 'MapStringStaticFilesHandler',
    as HashRef[StaticFilesHandler()];

declare 'HttpHeadersEntry',
    as InstanceOf['Google::Appengine::V1::AppYaml::StaticFilesHandler::HttpHeadersEntry'];

coerce 'HttpHeadersEntry',
    from HashRef, via { 'Google::Appengine::V1::AppYaml::StaticFilesHandler::HttpHeadersEntry'->new($_) };

declare 'RepeatedHttpHeadersEntry',
    as ArrayRef[HttpHeadersEntry()];

coerce 'RepeatedHttpHeadersEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1::AppYaml::StaticFilesHandler::HttpHeadersEntry'->new($_) } @$_ ] };

declare 'MapStringHttpHeadersEntry',
    as HashRef[HttpHeadersEntry()];

declare 'ScriptHandler',
    as InstanceOf['Google::Appengine::V1::AppYaml::ScriptHandler'];

coerce 'ScriptHandler',
    from HashRef, via { 'Google::Appengine::V1::AppYaml::ScriptHandler'->new($_) };

declare 'RepeatedScriptHandler',
    as ArrayRef[ScriptHandler()];

coerce 'RepeatedScriptHandler',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1::AppYaml::ScriptHandler'->new($_) } @$_ ] };

declare 'MapStringScriptHandler',
    as HashRef[ScriptHandler()];

declare 'ApiEndpointHandler',
    as InstanceOf['Google::Appengine::V1::AppYaml::ApiEndpointHandler'];

coerce 'ApiEndpointHandler',
    from HashRef, via { 'Google::Appengine::V1::AppYaml::ApiEndpointHandler'->new($_) };

declare 'RepeatedApiEndpointHandler',
    as ArrayRef[ApiEndpointHandler()];

coerce 'RepeatedApiEndpointHandler',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1::AppYaml::ApiEndpointHandler'->new($_) } @$_ ] };

declare 'MapStringApiEndpointHandler',
    as HashRef[ApiEndpointHandler()];

declare 'HealthCheck',
    as InstanceOf['Google::Appengine::V1::AppYaml::HealthCheck'];

coerce 'HealthCheck',
    from HashRef, via { 'Google::Appengine::V1::AppYaml::HealthCheck'->new($_) };

declare 'RepeatedHealthCheck',
    as ArrayRef[HealthCheck()];

coerce 'RepeatedHealthCheck',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1::AppYaml::HealthCheck'->new($_) } @$_ ] };

declare 'MapStringHealthCheck',
    as HashRef[HealthCheck()];

declare 'ReadinessCheck',
    as InstanceOf['Google::Appengine::V1::AppYaml::ReadinessCheck'];

coerce 'ReadinessCheck',
    from HashRef, via { 'Google::Appengine::V1::AppYaml::ReadinessCheck'->new($_) };

declare 'RepeatedReadinessCheck',
    as ArrayRef[ReadinessCheck()];

coerce 'RepeatedReadinessCheck',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1::AppYaml::ReadinessCheck'->new($_) } @$_ ] };

declare 'MapStringReadinessCheck',
    as HashRef[ReadinessCheck()];

declare 'LivenessCheck',
    as InstanceOf['Google::Appengine::V1::AppYaml::LivenessCheck'];

coerce 'LivenessCheck',
    from HashRef, via { 'Google::Appengine::V1::AppYaml::LivenessCheck'->new($_) };

declare 'RepeatedLivenessCheck',
    as ArrayRef[LivenessCheck()];

coerce 'RepeatedLivenessCheck',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1::AppYaml::LivenessCheck'->new($_) } @$_ ] };

declare 'MapStringLivenessCheck',
    as HashRef[LivenessCheck()];

declare 'Library',
    as InstanceOf['Google::Appengine::V1::AppYaml::Library'];

coerce 'Library',
    from HashRef, via { 'Google::Appengine::V1::AppYaml::Library'->new($_) };

declare 'RepeatedLibrary',
    as ArrayRef[Library()];

coerce 'RepeatedLibrary',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1::AppYaml::Library'->new($_) } @$_ ] };

declare 'MapStringLibrary',
    as HashRef[Library()];

1;

__END__

=head1 NAME

Google::Appengine::V1::AppYaml::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
