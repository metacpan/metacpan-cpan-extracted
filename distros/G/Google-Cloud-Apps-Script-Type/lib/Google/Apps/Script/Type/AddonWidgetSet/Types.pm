package Google::Apps::Script::Type::AddonWidgetSet::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AddOnWidgetSet',
    as InstanceOf['Google::Apps::Script::Type::AddonWidgetSet::AddOnWidgetSet'];

coerce 'AddOnWidgetSet',
    from HashRef, via { 'Google::Apps::Script::Type::AddonWidgetSet::AddOnWidgetSet'->new($_) };

declare 'RepeatedAddOnWidgetSet',
    as ArrayRef[AddOnWidgetSet()];

coerce 'RepeatedAddOnWidgetSet',
    from ArrayRef[HashRef], via { [ map { 'Google::Apps::Script::Type::AddonWidgetSet::AddOnWidgetSet'->new($_) } @$_ ] };

declare 'MapStringAddOnWidgetSet',
    as HashRef[AddOnWidgetSet()];

declare 'WidgetType',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Apps::Script::Type::AddonWidgetSet::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
