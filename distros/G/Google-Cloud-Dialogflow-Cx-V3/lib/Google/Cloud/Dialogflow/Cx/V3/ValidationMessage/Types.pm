package Google::Cloud::Dialogflow::Cx::V3::ValidationMessage::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ValidationMessage',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::ValidationMessage::ValidationMessage'];

coerce 'ValidationMessage',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::ValidationMessage::ValidationMessage'->new($_) };

declare 'RepeatedValidationMessage',
    as ArrayRef[ValidationMessage()];

coerce 'RepeatedValidationMessage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::ValidationMessage::ValidationMessage'->new($_) } @$_ ] };

declare 'MapStringValidationMessage',
    as HashRef[ValidationMessage()];

declare 'ResourceType',
    as (Int | Str);

declare 'Severity',
    as (Int | Str);

declare 'ResourceName',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::ValidationMessage::ResourceName'];

coerce 'ResourceName',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::ValidationMessage::ResourceName'->new($_) };

declare 'RepeatedResourceName',
    as ArrayRef[ResourceName()];

coerce 'RepeatedResourceName',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::ValidationMessage::ResourceName'->new($_) } @$_ ] };

declare 'MapStringResourceName',
    as HashRef[ResourceName()];

1;

__END__

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3::ValidationMessage::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
