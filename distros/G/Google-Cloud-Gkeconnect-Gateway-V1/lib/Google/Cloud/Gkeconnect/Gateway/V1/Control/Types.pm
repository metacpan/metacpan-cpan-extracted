package Google::Cloud::Gkeconnect::Gateway::V1::Control::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GenerateCredentialsRequest',
    as InstanceOf['Google::Cloud::Gkeconnect::Gateway::V1::Control::GenerateCredentialsRequest'];

coerce 'GenerateCredentialsRequest',
    from HashRef, via { 'Google::Cloud::Gkeconnect::Gateway::V1::Control::GenerateCredentialsRequest'->new($_) };

declare 'RepeatedGenerateCredentialsRequest',
    as ArrayRef[GenerateCredentialsRequest()];

coerce 'RepeatedGenerateCredentialsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkeconnect::Gateway::V1::Control::GenerateCredentialsRequest'->new($_) } @$_ ] };

declare 'MapStringGenerateCredentialsRequest',
    as HashRef[GenerateCredentialsRequest()];

declare 'OperatingSystem',
    as (Int | Str);

declare 'GenerateCredentialsResponse',
    as InstanceOf['Google::Cloud::Gkeconnect::Gateway::V1::Control::GenerateCredentialsResponse'];

coerce 'GenerateCredentialsResponse',
    from HashRef, via { 'Google::Cloud::Gkeconnect::Gateway::V1::Control::GenerateCredentialsResponse'->new($_) };

declare 'RepeatedGenerateCredentialsResponse',
    as ArrayRef[GenerateCredentialsResponse()];

coerce 'RepeatedGenerateCredentialsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkeconnect::Gateway::V1::Control::GenerateCredentialsResponse'->new($_) } @$_ ] };

declare 'MapStringGenerateCredentialsResponse',
    as HashRef[GenerateCredentialsResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Gkeconnect::Gateway::V1::Control::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
