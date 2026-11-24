package Google::Monitoring::Dashboard::V1::Text::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Text',
    as InstanceOf['Google::Monitoring::Dashboard::V1::Text::Text'];

coerce 'Text',
    from HashRef, via { 'Google::Monitoring::Dashboard::V1::Text::Text'->new($_) };

declare 'RepeatedText',
    as ArrayRef[Text()];

coerce 'RepeatedText',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::Dashboard::V1::Text::Text'->new($_) } @$_ ] };

declare 'MapStringText',
    as HashRef[Text()];

declare 'Format',
    as (Int | Str);

declare 'TextStyle',
    as InstanceOf['Google::Monitoring::Dashboard::V1::Text::Text::TextStyle'];

coerce 'TextStyle',
    from HashRef, via { 'Google::Monitoring::Dashboard::V1::Text::Text::TextStyle'->new($_) };

declare 'RepeatedTextStyle',
    as ArrayRef[TextStyle()];

coerce 'RepeatedTextStyle',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::Dashboard::V1::Text::Text::TextStyle'->new($_) } @$_ ] };

declare 'MapStringTextStyle',
    as HashRef[TextStyle()];

declare 'HorizontalAlignment',
    as (Int | Str);

declare 'VerticalAlignment',
    as (Int | Str);

declare 'PaddingSize',
    as (Int | Str);

declare 'FontSize',
    as (Int | Str);

declare 'PointerLocation',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Monitoring::Dashboard::V1::Text::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
