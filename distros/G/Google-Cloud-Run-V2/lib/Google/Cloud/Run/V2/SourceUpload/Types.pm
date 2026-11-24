package Google::Cloud::Run::V2::SourceUpload::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'UploadSourceRequest',
    as InstanceOf['Google::Cloud::Run::V2::SourceUpload::UploadSourceRequest'];

coerce 'UploadSourceRequest',
    from HashRef, via { 'Google::Cloud::Run::V2::SourceUpload::UploadSourceRequest'->new($_) };

declare 'RepeatedUploadSourceRequest',
    as ArrayRef[UploadSourceRequest()];

coerce 'RepeatedUploadSourceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::SourceUpload::UploadSourceRequest'->new($_) } @$_ ] };

declare 'MapStringUploadSourceRequest',
    as HashRef[UploadSourceRequest()];

declare 'UploadSourceResponse',
    as InstanceOf['Google::Cloud::Run::V2::SourceUpload::UploadSourceResponse'];

coerce 'UploadSourceResponse',
    from HashRef, via { 'Google::Cloud::Run::V2::SourceUpload::UploadSourceResponse'->new($_) };

declare 'RepeatedUploadSourceResponse',
    as ArrayRef[UploadSourceResponse()];

coerce 'RepeatedUploadSourceResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::SourceUpload::UploadSourceResponse'->new($_) } @$_ ] };

declare 'MapStringUploadSourceResponse',
    as HashRef[UploadSourceResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Run::V2::SourceUpload::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
