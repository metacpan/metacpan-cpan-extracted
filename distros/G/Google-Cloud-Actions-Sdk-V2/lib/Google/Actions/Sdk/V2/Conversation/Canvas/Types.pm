package Google::Actions::Sdk::V2::Conversation::Canvas::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Canvas',
    as InstanceOf['Google::Actions::Sdk::V2::Conversation::Canvas::Canvas'];

coerce 'Canvas',
    from HashRef, via { 'Google::Actions::Sdk::V2::Conversation::Canvas::Canvas'->new($_) };

declare 'RepeatedCanvas',
    as ArrayRef[Canvas()];

coerce 'RepeatedCanvas',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Conversation::Canvas::Canvas'->new($_) } @$_ ] };

declare 'MapStringCanvas',
    as HashRef[Canvas()];

1;

__END__

=head1 NAME

Google::Actions::Sdk::V2::Conversation::Canvas::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
