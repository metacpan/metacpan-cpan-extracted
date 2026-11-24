package Google::Cloud::Contentwarehouse::V1::AsyncDocumentServiceRequest::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateDocumentMetadata',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::AsyncDocumentServiceRequest::CreateDocumentMetadata'];

coerce 'CreateDocumentMetadata',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::AsyncDocumentServiceRequest::CreateDocumentMetadata'->new($_) };

declare 'RepeatedCreateDocumentMetadata',
    as ArrayRef[CreateDocumentMetadata()];

coerce 'RepeatedCreateDocumentMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::AsyncDocumentServiceRequest::CreateDocumentMetadata'->new($_) } @$_ ] };

declare 'MapStringCreateDocumentMetadata',
    as HashRef[CreateDocumentMetadata()];

declare 'UpdateDocumentMetadata',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::AsyncDocumentServiceRequest::UpdateDocumentMetadata'];

coerce 'UpdateDocumentMetadata',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::AsyncDocumentServiceRequest::UpdateDocumentMetadata'->new($_) };

declare 'RepeatedUpdateDocumentMetadata',
    as ArrayRef[UpdateDocumentMetadata()];

coerce 'RepeatedUpdateDocumentMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::AsyncDocumentServiceRequest::UpdateDocumentMetadata'->new($_) } @$_ ] };

declare 'MapStringUpdateDocumentMetadata',
    as HashRef[UpdateDocumentMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Contentwarehouse::V1::AsyncDocumentServiceRequest::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
