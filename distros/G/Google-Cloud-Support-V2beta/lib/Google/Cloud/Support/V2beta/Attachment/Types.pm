package Google::Cloud::Support::V2beta::Attachment::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Attachment',
    as InstanceOf['Google::Cloud::Support::V2beta::Attachment::Attachment'];

coerce 'Attachment',
    from HashRef, via { 'Google::Cloud::Support::V2beta::Attachment::Attachment'->new($_) };

declare 'RepeatedAttachment',
    as ArrayRef[Attachment()];

coerce 'RepeatedAttachment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Support::V2beta::Attachment::Attachment'->new($_) } @$_ ] };

declare 'MapStringAttachment',
    as HashRef[Attachment()];

1;

__END__

=head1 NAME

Google::Cloud::Support::V2beta::Attachment::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
