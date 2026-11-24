package Google::Cloud::Support::V2beta::Comment::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Comment',
    as InstanceOf['Google::Cloud::Support::V2beta::Comment::Comment'];

coerce 'Comment',
    from HashRef, via { 'Google::Cloud::Support::V2beta::Comment::Comment'->new($_) };

declare 'RepeatedComment',
    as ArrayRef[Comment()];

coerce 'RepeatedComment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Support::V2beta::Comment::Comment'->new($_) } @$_ ] };

declare 'MapStringComment',
    as HashRef[Comment()];

1;

__END__

=head1 NAME

Google::Cloud::Support::V2beta::Comment::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
