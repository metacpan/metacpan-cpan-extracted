package Google::Cloud::Dialogflow::V2::CesTool::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CesToolSpec',
    as InstanceOf['Google::Cloud::Dialogflow::V2::CesTool::CesToolSpec'];

coerce 'CesToolSpec',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::CesTool::CesToolSpec'->new($_) };

declare 'RepeatedCesToolSpec',
    as ArrayRef[CesToolSpec()];

coerce 'RepeatedCesToolSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::CesTool::CesToolSpec'->new($_) } @$_ ] };

declare 'MapStringCesToolSpec',
    as HashRef[CesToolSpec()];

1;

__END__

=head1 NAME

Google::Cloud::Dialogflow::V2::CesTool::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
