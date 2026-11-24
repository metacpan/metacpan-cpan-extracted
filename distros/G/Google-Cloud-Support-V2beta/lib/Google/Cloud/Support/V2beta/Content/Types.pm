package Google::Cloud::Support::V2beta::Content::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'TextContent',
    as InstanceOf['Google::Cloud::Support::V2beta::Content::TextContent'];

coerce 'TextContent',
    from HashRef, via { 'Google::Cloud::Support::V2beta::Content::TextContent'->new($_) };

declare 'RepeatedTextContent',
    as ArrayRef[TextContent()];

coerce 'RepeatedTextContent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Support::V2beta::Content::TextContent'->new($_) } @$_ ] };

declare 'MapStringTextContent',
    as HashRef[TextContent()];

1;

__END__

=head1 NAME

Google::Cloud::Support::V2beta::Content::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
