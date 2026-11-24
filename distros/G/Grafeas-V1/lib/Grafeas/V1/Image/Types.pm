package Grafeas::V1::Image::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Layer',
    as InstanceOf['Grafeas::V1::Image::Layer'];

coerce 'Layer',
    from HashRef, via { 'Grafeas::V1::Image::Layer'->new($_) };

declare 'RepeatedLayer',
    as ArrayRef[Layer()];

coerce 'RepeatedLayer',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Image::Layer'->new($_) } @$_ ] };

declare 'MapStringLayer',
    as HashRef[Layer()];

declare 'Fingerprint',
    as InstanceOf['Grafeas::V1::Image::Fingerprint'];

coerce 'Fingerprint',
    from HashRef, via { 'Grafeas::V1::Image::Fingerprint'->new($_) };

declare 'RepeatedFingerprint',
    as ArrayRef[Fingerprint()];

coerce 'RepeatedFingerprint',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Image::Fingerprint'->new($_) } @$_ ] };

declare 'MapStringFingerprint',
    as HashRef[Fingerprint()];

declare 'ImageNote',
    as InstanceOf['Grafeas::V1::Image::ImageNote'];

coerce 'ImageNote',
    from HashRef, via { 'Grafeas::V1::Image::ImageNote'->new($_) };

declare 'RepeatedImageNote',
    as ArrayRef[ImageNote()];

coerce 'RepeatedImageNote',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Image::ImageNote'->new($_) } @$_ ] };

declare 'MapStringImageNote',
    as HashRef[ImageNote()];

declare 'ImageOccurrence',
    as InstanceOf['Grafeas::V1::Image::ImageOccurrence'];

coerce 'ImageOccurrence',
    from HashRef, via { 'Grafeas::V1::Image::ImageOccurrence'->new($_) };

declare 'RepeatedImageOccurrence',
    as ArrayRef[ImageOccurrence()];

coerce 'RepeatedImageOccurrence',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Image::ImageOccurrence'->new($_) } @$_ ] };

declare 'MapStringImageOccurrence',
    as HashRef[ImageOccurrence()];

1;

__END__

=head1 NAME

Grafeas::V1::Image::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
