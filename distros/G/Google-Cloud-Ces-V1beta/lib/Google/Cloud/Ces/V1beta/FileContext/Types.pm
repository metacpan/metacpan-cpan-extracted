package Google::Cloud::Ces::V1beta::FileContext::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'FileContext',
    as InstanceOf['Google::Cloud::Ces::V1beta::FileContext::FileContext'];

coerce 'FileContext',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::FileContext::FileContext'->new($_) };

declare 'RepeatedFileContext',
    as ArrayRef[FileContext()];

coerce 'RepeatedFileContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::FileContext::FileContext'->new($_) } @$_ ] };

declare 'MapStringFileContext',
    as HashRef[FileContext()];

declare 'FileBytes',
    as InstanceOf['Google::Cloud::Ces::V1beta::FileContext::FileContext::FileBytes'];

coerce 'FileBytes',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::FileContext::FileContext::FileBytes'->new($_) };

declare 'RepeatedFileBytes',
    as ArrayRef[FileBytes()];

coerce 'RepeatedFileBytes',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::FileContext::FileContext::FileBytes'->new($_) } @$_ ] };

declare 'MapStringFileBytes',
    as HashRef[FileBytes()];

1;

__END__

=head1 NAME

Google::Cloud::Ces::V1beta::FileContext::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
