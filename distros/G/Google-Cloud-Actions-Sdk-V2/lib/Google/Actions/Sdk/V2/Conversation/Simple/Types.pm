package Google::Actions::Sdk::V2::Conversation::Simple::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Simple',
    as InstanceOf['Google::Actions::Sdk::V2::Conversation::Simple::Simple'];

coerce 'Simple',
    from HashRef, via { 'Google::Actions::Sdk::V2::Conversation::Simple::Simple'->new($_) };

declare 'RepeatedSimple',
    as ArrayRef[Simple()];

coerce 'RepeatedSimple',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Conversation::Simple::Simple'->new($_) } @$_ ] };

declare 'MapStringSimple',
    as HashRef[Simple()];

1;

__END__

=head1 NAME

Google::Actions::Sdk::V2::Conversation::Simple::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
