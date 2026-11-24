package Google::Actions::Sdk::V2::Conversation::Link::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'UrlHint',
    as (Int | Str);

declare 'Link',
    as InstanceOf['Google::Actions::Sdk::V2::Conversation::Link::Link'];

coerce 'Link',
    from HashRef, via { 'Google::Actions::Sdk::V2::Conversation::Link::Link'->new($_) };

declare 'RepeatedLink',
    as ArrayRef[Link()];

coerce 'RepeatedLink',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Conversation::Link::Link'->new($_) } @$_ ] };

declare 'MapStringLink',
    as HashRef[Link()];

declare 'OpenUrl',
    as InstanceOf['Google::Actions::Sdk::V2::Conversation::Link::OpenUrl'];

coerce 'OpenUrl',
    from HashRef, via { 'Google::Actions::Sdk::V2::Conversation::Link::OpenUrl'->new($_) };

declare 'RepeatedOpenUrl',
    as ArrayRef[OpenUrl()];

coerce 'RepeatedOpenUrl',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Conversation::Link::OpenUrl'->new($_) } @$_ ] };

declare 'MapStringOpenUrl',
    as HashRef[OpenUrl()];

1;

__END__

=head1 NAME

Google::Actions::Sdk::V2::Conversation::Link::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
