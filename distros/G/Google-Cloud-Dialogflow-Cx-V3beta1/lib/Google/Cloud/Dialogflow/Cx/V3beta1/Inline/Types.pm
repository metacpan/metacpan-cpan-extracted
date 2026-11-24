package Google::Cloud::Dialogflow::Cx::V3beta1::Inline::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'InlineDestination',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Inline::InlineDestination'];

coerce 'InlineDestination',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Inline::InlineDestination'->new($_) };

declare 'RepeatedInlineDestination',
    as ArrayRef[InlineDestination()];

coerce 'RepeatedInlineDestination',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Inline::InlineDestination'->new($_) } @$_ ] };

declare 'MapStringInlineDestination',
    as HashRef[InlineDestination()];

declare 'InlineSource',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Inline::InlineSource'];

coerce 'InlineSource',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Inline::InlineSource'->new($_) };

declare 'RepeatedInlineSource',
    as ArrayRef[InlineSource()];

coerce 'RepeatedInlineSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Inline::InlineSource'->new($_) } @$_ ] };

declare 'MapStringInlineSource',
    as HashRef[InlineSource()];

1;

__END__

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3beta1::Inline::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
