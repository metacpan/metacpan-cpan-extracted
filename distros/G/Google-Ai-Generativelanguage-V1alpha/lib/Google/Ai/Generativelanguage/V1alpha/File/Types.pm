package Google::Ai::Generativelanguage::V1alpha::File::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'File',
    as InstanceOf['Google::Ai::Generativelanguage::V1alpha::File::File'];

coerce 'File',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1alpha::File::File'->new($_) };

declare 'RepeatedFile',
    as ArrayRef[File()];

coerce 'RepeatedFile',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1alpha::File::File'->new($_) } @$_ ] };

declare 'MapStringFile',
    as HashRef[File()];

declare 'State',
    as (Int | Str);

declare 'VideoMetadata',
    as InstanceOf['Google::Ai::Generativelanguage::V1alpha::File::VideoMetadata'];

coerce 'VideoMetadata',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1alpha::File::VideoMetadata'->new($_) };

declare 'RepeatedVideoMetadata',
    as ArrayRef[VideoMetadata()];

coerce 'RepeatedVideoMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1alpha::File::VideoMetadata'->new($_) } @$_ ] };

declare 'MapStringVideoMetadata',
    as HashRef[VideoMetadata()];

1;

__END__

=head1 NAME

Google::Ai::Generativelanguage::V1alpha::File::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
