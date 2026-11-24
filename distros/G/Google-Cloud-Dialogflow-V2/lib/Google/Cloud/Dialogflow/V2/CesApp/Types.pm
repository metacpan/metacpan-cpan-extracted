package Google::Cloud::Dialogflow::V2::CesApp::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CesAppSpec',
    as InstanceOf['Google::Cloud::Dialogflow::V2::CesApp::CesAppSpec'];

coerce 'CesAppSpec',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::CesApp::CesAppSpec'->new($_) };

declare 'RepeatedCesAppSpec',
    as ArrayRef[CesAppSpec()];

coerce 'RepeatedCesAppSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::CesApp::CesAppSpec'->new($_) } @$_ ] };

declare 'MapStringCesAppSpec',
    as HashRef[CesAppSpec()];

1;

__END__

=head1 NAME

Google::Cloud::Dialogflow::V2::CesApp::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
