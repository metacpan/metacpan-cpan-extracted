package Google::Actions::Sdk::V2::Conversation::Image::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Image',
    as InstanceOf['Google::Actions::Sdk::V2::Conversation::Image::Image'];

coerce 'Image',
    from HashRef, via { 'Google::Actions::Sdk::V2::Conversation::Image::Image'->new($_) };

declare 'RepeatedImage',
    as ArrayRef[Image()];

coerce 'RepeatedImage',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Conversation::Image::Image'->new($_) } @$_ ] };

declare 'MapStringImage',
    as HashRef[Image()];

declare 'ImageFill',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Actions::Sdk::V2::Conversation::Image::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
