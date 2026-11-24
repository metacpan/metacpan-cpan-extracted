package Google::Actions::Sdk::V2::Conversation::Content::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Content',
    as InstanceOf['Google::Actions::Sdk::V2::Conversation::Content::Content'];

coerce 'Content',
    from HashRef, via { 'Google::Actions::Sdk::V2::Conversation::Content::Content'->new($_) };

declare 'RepeatedContent',
    as ArrayRef[Content()];

coerce 'RepeatedContent',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Conversation::Content::Content'->new($_) } @$_ ] };

declare 'MapStringContent',
    as HashRef[Content()];

1;

__END__

=head1 NAME

Google::Actions::Sdk::V2::Conversation::Content::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
