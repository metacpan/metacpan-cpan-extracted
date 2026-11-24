package Google::Cloud::Discoveryengine::V1alpha::Document::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Document',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::Document::Document'];

coerce 'Document',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::Document::Document'->new($_) };

declare 'RepeatedDocument',
    as ArrayRef[Document()];

coerce 'RepeatedDocument',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::Document::Document'->new($_) } @$_ ] };

declare 'MapStringDocument',
    as HashRef[Document()];

declare 'Content',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::Document::Document::Content'];

coerce 'Content',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::Document::Document::Content'->new($_) };

declare 'RepeatedContent',
    as ArrayRef[Content()];

coerce 'RepeatedContent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::Document::Document::Content'->new($_) } @$_ ] };

declare 'MapStringContent',
    as HashRef[Content()];

declare 'AclInfo',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::Document::Document::AclInfo'];

coerce 'AclInfo',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::Document::Document::AclInfo'->new($_) };

declare 'RepeatedAclInfo',
    as ArrayRef[AclInfo()];

coerce 'RepeatedAclInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::Document::Document::AclInfo'->new($_) } @$_ ] };

declare 'MapStringAclInfo',
    as HashRef[AclInfo()];

declare 'AccessRestriction',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::Document::Document::AclInfo::AccessRestriction'];

coerce 'AccessRestriction',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::Document::Document::AclInfo::AccessRestriction'->new($_) };

declare 'RepeatedAccessRestriction',
    as ArrayRef[AccessRestriction()];

coerce 'RepeatedAccessRestriction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::Document::Document::AclInfo::AccessRestriction'->new($_) } @$_ ] };

declare 'MapStringAccessRestriction',
    as HashRef[AccessRestriction()];

declare 'IndexStatus',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::Document::Document::IndexStatus'];

coerce 'IndexStatus',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::Document::Document::IndexStatus'->new($_) };

declare 'RepeatedIndexStatus',
    as ArrayRef[IndexStatus()];

coerce 'RepeatedIndexStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::Document::Document::IndexStatus'->new($_) } @$_ ] };

declare 'MapStringIndexStatus',
    as HashRef[IndexStatus()];

declare 'ProcessedDocument',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::Document::ProcessedDocument'];

coerce 'ProcessedDocument',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::Document::ProcessedDocument'->new($_) };

declare 'RepeatedProcessedDocument',
    as ArrayRef[ProcessedDocument()];

coerce 'RepeatedProcessedDocument',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::Document::ProcessedDocument'->new($_) } @$_ ] };

declare 'MapStringProcessedDocument',
    as HashRef[ProcessedDocument()];

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1alpha::Document::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
