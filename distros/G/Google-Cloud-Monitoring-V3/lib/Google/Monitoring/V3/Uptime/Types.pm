package Google::Monitoring::V3::Uptime::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'UptimeCheckRegion',
    as (Int | Str);

declare 'GroupResourceType',
    as (Int | Str);

declare 'InternalChecker',
    as InstanceOf['Google::Monitoring::V3::Uptime::InternalChecker'];

coerce 'InternalChecker',
    from HashRef, via { 'Google::Monitoring::V3::Uptime::InternalChecker'->new($_) };

declare 'RepeatedInternalChecker',
    as ArrayRef[InternalChecker()];

coerce 'RepeatedInternalChecker',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Uptime::InternalChecker'->new($_) } @$_ ] };

declare 'MapStringInternalChecker',
    as HashRef[InternalChecker()];

declare 'State',
    as (Int | Str);

declare 'SyntheticMonitorTarget',
    as InstanceOf['Google::Monitoring::V3::Uptime::SyntheticMonitorTarget'];

coerce 'SyntheticMonitorTarget',
    from HashRef, via { 'Google::Monitoring::V3::Uptime::SyntheticMonitorTarget'->new($_) };

declare 'RepeatedSyntheticMonitorTarget',
    as ArrayRef[SyntheticMonitorTarget()];

coerce 'RepeatedSyntheticMonitorTarget',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Uptime::SyntheticMonitorTarget'->new($_) } @$_ ] };

declare 'MapStringSyntheticMonitorTarget',
    as HashRef[SyntheticMonitorTarget()];

declare 'CloudFunctionV2Target',
    as InstanceOf['Google::Monitoring::V3::Uptime::SyntheticMonitorTarget::CloudFunctionV2Target'];

coerce 'CloudFunctionV2Target',
    from HashRef, via { 'Google::Monitoring::V3::Uptime::SyntheticMonitorTarget::CloudFunctionV2Target'->new($_) };

declare 'RepeatedCloudFunctionV2Target',
    as ArrayRef[CloudFunctionV2Target()];

coerce 'RepeatedCloudFunctionV2Target',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Uptime::SyntheticMonitorTarget::CloudFunctionV2Target'->new($_) } @$_ ] };

declare 'MapStringCloudFunctionV2Target',
    as HashRef[CloudFunctionV2Target()];

declare 'UptimeCheckConfig',
    as InstanceOf['Google::Monitoring::V3::Uptime::UptimeCheckConfig'];

coerce 'UptimeCheckConfig',
    from HashRef, via { 'Google::Monitoring::V3::Uptime::UptimeCheckConfig'->new($_) };

declare 'RepeatedUptimeCheckConfig',
    as ArrayRef[UptimeCheckConfig()];

coerce 'RepeatedUptimeCheckConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Uptime::UptimeCheckConfig'->new($_) } @$_ ] };

declare 'MapStringUptimeCheckConfig',
    as HashRef[UptimeCheckConfig()];

declare 'CheckerType',
    as (Int | Str);

declare 'ResourceGroup',
    as InstanceOf['Google::Monitoring::V3::Uptime::UptimeCheckConfig::ResourceGroup'];

coerce 'ResourceGroup',
    from HashRef, via { 'Google::Monitoring::V3::Uptime::UptimeCheckConfig::ResourceGroup'->new($_) };

declare 'RepeatedResourceGroup',
    as ArrayRef[ResourceGroup()];

coerce 'RepeatedResourceGroup',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Uptime::UptimeCheckConfig::ResourceGroup'->new($_) } @$_ ] };

declare 'MapStringResourceGroup',
    as HashRef[ResourceGroup()];

declare 'PingConfig',
    as InstanceOf['Google::Monitoring::V3::Uptime::UptimeCheckConfig::PingConfig'];

coerce 'PingConfig',
    from HashRef, via { 'Google::Monitoring::V3::Uptime::UptimeCheckConfig::PingConfig'->new($_) };

declare 'RepeatedPingConfig',
    as ArrayRef[PingConfig()];

coerce 'RepeatedPingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Uptime::UptimeCheckConfig::PingConfig'->new($_) } @$_ ] };

declare 'MapStringPingConfig',
    as HashRef[PingConfig()];

declare 'HttpCheck',
    as InstanceOf['Google::Monitoring::V3::Uptime::UptimeCheckConfig::HttpCheck'];

coerce 'HttpCheck',
    from HashRef, via { 'Google::Monitoring::V3::Uptime::UptimeCheckConfig::HttpCheck'->new($_) };

declare 'RepeatedHttpCheck',
    as ArrayRef[HttpCheck()];

coerce 'RepeatedHttpCheck',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Uptime::UptimeCheckConfig::HttpCheck'->new($_) } @$_ ] };

declare 'MapStringHttpCheck',
    as HashRef[HttpCheck()];

declare 'RequestMethod',
    as (Int | Str);

declare 'ContentType',
    as (Int | Str);

declare 'BasicAuthentication',
    as InstanceOf['Google::Monitoring::V3::Uptime::UptimeCheckConfig::HttpCheck::BasicAuthentication'];

coerce 'BasicAuthentication',
    from HashRef, via { 'Google::Monitoring::V3::Uptime::UptimeCheckConfig::HttpCheck::BasicAuthentication'->new($_) };

declare 'RepeatedBasicAuthentication',
    as ArrayRef[BasicAuthentication()];

coerce 'RepeatedBasicAuthentication',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Uptime::UptimeCheckConfig::HttpCheck::BasicAuthentication'->new($_) } @$_ ] };

declare 'MapStringBasicAuthentication',
    as HashRef[BasicAuthentication()];

declare 'ResponseStatusCode',
    as InstanceOf['Google::Monitoring::V3::Uptime::UptimeCheckConfig::HttpCheck::ResponseStatusCode'];

coerce 'ResponseStatusCode',
    from HashRef, via { 'Google::Monitoring::V3::Uptime::UptimeCheckConfig::HttpCheck::ResponseStatusCode'->new($_) };

declare 'RepeatedResponseStatusCode',
    as ArrayRef[ResponseStatusCode()];

coerce 'RepeatedResponseStatusCode',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Uptime::UptimeCheckConfig::HttpCheck::ResponseStatusCode'->new($_) } @$_ ] };

declare 'MapStringResponseStatusCode',
    as HashRef[ResponseStatusCode()];

declare 'StatusClass',
    as (Int | Str);

declare 'ServiceAgentAuthentication',
    as InstanceOf['Google::Monitoring::V3::Uptime::UptimeCheckConfig::HttpCheck::ServiceAgentAuthentication'];

coerce 'ServiceAgentAuthentication',
    from HashRef, via { 'Google::Monitoring::V3::Uptime::UptimeCheckConfig::HttpCheck::ServiceAgentAuthentication'->new($_) };

declare 'RepeatedServiceAgentAuthentication',
    as ArrayRef[ServiceAgentAuthentication()];

coerce 'RepeatedServiceAgentAuthentication',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Uptime::UptimeCheckConfig::HttpCheck::ServiceAgentAuthentication'->new($_) } @$_ ] };

declare 'MapStringServiceAgentAuthentication',
    as HashRef[ServiceAgentAuthentication()];

declare 'ServiceAgentAuthenticationType',
    as (Int | Str);

declare 'HeadersEntry',
    as InstanceOf['Google::Monitoring::V3::Uptime::UptimeCheckConfig::HttpCheck::HeadersEntry'];

coerce 'HeadersEntry',
    from HashRef, via { 'Google::Monitoring::V3::Uptime::UptimeCheckConfig::HttpCheck::HeadersEntry'->new($_) };

declare 'RepeatedHeadersEntry',
    as ArrayRef[HeadersEntry()];

coerce 'RepeatedHeadersEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Uptime::UptimeCheckConfig::HttpCheck::HeadersEntry'->new($_) } @$_ ] };

declare 'MapStringHeadersEntry',
    as HashRef[HeadersEntry()];

declare 'TcpCheck',
    as InstanceOf['Google::Monitoring::V3::Uptime::UptimeCheckConfig::TcpCheck'];

coerce 'TcpCheck',
    from HashRef, via { 'Google::Monitoring::V3::Uptime::UptimeCheckConfig::TcpCheck'->new($_) };

declare 'RepeatedTcpCheck',
    as ArrayRef[TcpCheck()];

coerce 'RepeatedTcpCheck',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Uptime::UptimeCheckConfig::TcpCheck'->new($_) } @$_ ] };

declare 'MapStringTcpCheck',
    as HashRef[TcpCheck()];

declare 'ContentMatcher',
    as InstanceOf['Google::Monitoring::V3::Uptime::UptimeCheckConfig::ContentMatcher'];

coerce 'ContentMatcher',
    from HashRef, via { 'Google::Monitoring::V3::Uptime::UptimeCheckConfig::ContentMatcher'->new($_) };

declare 'RepeatedContentMatcher',
    as ArrayRef[ContentMatcher()];

coerce 'RepeatedContentMatcher',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Uptime::UptimeCheckConfig::ContentMatcher'->new($_) } @$_ ] };

declare 'MapStringContentMatcher',
    as HashRef[ContentMatcher()];

declare 'ContentMatcherOption',
    as (Int | Str);

declare 'JsonPathMatcher',
    as InstanceOf['Google::Monitoring::V3::Uptime::UptimeCheckConfig::ContentMatcher::JsonPathMatcher'];

coerce 'JsonPathMatcher',
    from HashRef, via { 'Google::Monitoring::V3::Uptime::UptimeCheckConfig::ContentMatcher::JsonPathMatcher'->new($_) };

declare 'RepeatedJsonPathMatcher',
    as ArrayRef[JsonPathMatcher()];

coerce 'RepeatedJsonPathMatcher',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Uptime::UptimeCheckConfig::ContentMatcher::JsonPathMatcher'->new($_) } @$_ ] };

declare 'MapStringJsonPathMatcher',
    as HashRef[JsonPathMatcher()];

declare 'JsonPathMatcherOption',
    as (Int | Str);

declare 'UserLabelsEntry',
    as InstanceOf['Google::Monitoring::V3::Uptime::UptimeCheckConfig::UserLabelsEntry'];

coerce 'UserLabelsEntry',
    from HashRef, via { 'Google::Monitoring::V3::Uptime::UptimeCheckConfig::UserLabelsEntry'->new($_) };

declare 'RepeatedUserLabelsEntry',
    as ArrayRef[UserLabelsEntry()];

coerce 'RepeatedUserLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Uptime::UptimeCheckConfig::UserLabelsEntry'->new($_) } @$_ ] };

declare 'MapStringUserLabelsEntry',
    as HashRef[UserLabelsEntry()];

declare 'UptimeCheckIp',
    as InstanceOf['Google::Monitoring::V3::Uptime::UptimeCheckIp'];

coerce 'UptimeCheckIp',
    from HashRef, via { 'Google::Monitoring::V3::Uptime::UptimeCheckIp'->new($_) };

declare 'RepeatedUptimeCheckIp',
    as ArrayRef[UptimeCheckIp()];

coerce 'RepeatedUptimeCheckIp',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Uptime::UptimeCheckIp'->new($_) } @$_ ] };

declare 'MapStringUptimeCheckIp',
    as HashRef[UptimeCheckIp()];

1;

__END__

=head1 NAME

Google::Monitoring::V3::Uptime::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
