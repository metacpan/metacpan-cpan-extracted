package Google::Cloud::Channel::V1::Common::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'EduData',
    as InstanceOf['Google::Cloud::Channel::V1::Common::EduData'];

coerce 'EduData',
    from HashRef, via { 'Google::Cloud::Channel::V1::Common::EduData'->new($_) };

declare 'RepeatedEduData',
    as ArrayRef[EduData()];

coerce 'RepeatedEduData',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Common::EduData'->new($_) } @$_ ] };

declare 'MapStringEduData',
    as HashRef[EduData()];

declare 'InstituteType',
    as (Int | Str);

declare 'InstituteSize',
    as (Int | Str);

declare 'CloudIdentityInfo',
    as InstanceOf['Google::Cloud::Channel::V1::Common::CloudIdentityInfo'];

coerce 'CloudIdentityInfo',
    from HashRef, via { 'Google::Cloud::Channel::V1::Common::CloudIdentityInfo'->new($_) };

declare 'RepeatedCloudIdentityInfo',
    as ArrayRef[CloudIdentityInfo()];

coerce 'RepeatedCloudIdentityInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Common::CloudIdentityInfo'->new($_) } @$_ ] };

declare 'MapStringCloudIdentityInfo',
    as HashRef[CloudIdentityInfo()];

declare 'CustomerType',
    as (Int | Str);

declare 'Value',
    as InstanceOf['Google::Cloud::Channel::V1::Common::Value'];

coerce 'Value',
    from HashRef, via { 'Google::Cloud::Channel::V1::Common::Value'->new($_) };

declare 'RepeatedValue',
    as ArrayRef[Value()];

coerce 'RepeatedValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Common::Value'->new($_) } @$_ ] };

declare 'MapStringValue',
    as HashRef[Value()];

declare 'AdminUser',
    as InstanceOf['Google::Cloud::Channel::V1::Common::AdminUser'];

coerce 'AdminUser',
    from HashRef, via { 'Google::Cloud::Channel::V1::Common::AdminUser'->new($_) };

declare 'RepeatedAdminUser',
    as ArrayRef[AdminUser()];

coerce 'RepeatedAdminUser',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Common::AdminUser'->new($_) } @$_ ] };

declare 'MapStringAdminUser',
    as HashRef[AdminUser()];

1;

__END__

=head1 NAME

Google::Cloud::Channel::V1::Common::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
