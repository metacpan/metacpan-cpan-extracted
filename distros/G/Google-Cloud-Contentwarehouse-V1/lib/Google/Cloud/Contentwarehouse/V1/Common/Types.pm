package Google::Cloud::Contentwarehouse::V1::Common::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'UpdateType',
    as (Int | Str);

declare 'DatabaseType',
    as (Int | Str);

declare 'AccessControlMode',
    as (Int | Str);

declare 'DocumentCreatorDefaultRole',
    as (Int | Str);

declare 'RequestMetadata',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::Common::RequestMetadata'];

coerce 'RequestMetadata',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::Common::RequestMetadata'->new($_) };

declare 'RepeatedRequestMetadata',
    as ArrayRef[RequestMetadata()];

coerce 'RepeatedRequestMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::Common::RequestMetadata'->new($_) } @$_ ] };

declare 'MapStringRequestMetadata',
    as HashRef[RequestMetadata()];

declare 'ResponseMetadata',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::Common::ResponseMetadata'];

coerce 'ResponseMetadata',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::Common::ResponseMetadata'->new($_) };

declare 'RepeatedResponseMetadata',
    as ArrayRef[ResponseMetadata()];

coerce 'RepeatedResponseMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::Common::ResponseMetadata'->new($_) } @$_ ] };

declare 'MapStringResponseMetadata',
    as HashRef[ResponseMetadata()];

declare 'UserInfo',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::Common::UserInfo'];

coerce 'UserInfo',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::Common::UserInfo'->new($_) };

declare 'RepeatedUserInfo',
    as ArrayRef[UserInfo()];

coerce 'RepeatedUserInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::Common::UserInfo'->new($_) } @$_ ] };

declare 'MapStringUserInfo',
    as HashRef[UserInfo()];

declare 'UpdateOptions',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::Common::UpdateOptions'];

coerce 'UpdateOptions',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::Common::UpdateOptions'->new($_) };

declare 'RepeatedUpdateOptions',
    as ArrayRef[UpdateOptions()];

coerce 'RepeatedUpdateOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::Common::UpdateOptions'->new($_) } @$_ ] };

declare 'MapStringUpdateOptions',
    as HashRef[UpdateOptions()];

declare 'MergeFieldsOptions',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::Common::MergeFieldsOptions'];

coerce 'MergeFieldsOptions',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::Common::MergeFieldsOptions'->new($_) };

declare 'RepeatedMergeFieldsOptions',
    as ArrayRef[MergeFieldsOptions()];

coerce 'RepeatedMergeFieldsOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::Common::MergeFieldsOptions'->new($_) } @$_ ] };

declare 'MapStringMergeFieldsOptions',
    as HashRef[MergeFieldsOptions()];

1;

__END__

=head1 NAME

Google::Cloud::Contentwarehouse::V1::Common::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
