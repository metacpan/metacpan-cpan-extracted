package Google::Ai::Generativelanguage::V1beta::File::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'File',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::File::File'];

coerce 'File',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::File::File'->new($_) };

declare 'RepeatedFile',
    as ArrayRef[File()];

coerce 'RepeatedFile',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::File::File'->new($_) } @$_ ] };

declare 'MapStringFile',
    as HashRef[File()];

declare 'State',
    as (Int | Str);

declare 'Source',
    as (Int | Str);

declare 'VideoFileMetadata',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::File::VideoFileMetadata'];

coerce 'VideoFileMetadata',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::File::VideoFileMetadata'->new($_) };

declare 'RepeatedVideoFileMetadata',
    as ArrayRef[VideoFileMetadata()];

coerce 'RepeatedVideoFileMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::File::VideoFileMetadata'->new($_) } @$_ ] };

declare 'MapStringVideoFileMetadata',
    as HashRef[VideoFileMetadata()];

1;

__END__

=head1 NAME

Google::Ai::Generativelanguage::V1beta::File::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
