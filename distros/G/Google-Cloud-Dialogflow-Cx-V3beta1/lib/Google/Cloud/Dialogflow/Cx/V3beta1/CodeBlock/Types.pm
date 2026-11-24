package Google::Cloud::Dialogflow::Cx::V3beta1::CodeBlock::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CodeBlock',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::CodeBlock::CodeBlock'];

coerce 'CodeBlock',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::CodeBlock::CodeBlock'->new($_) };

declare 'RepeatedCodeBlock',
    as ArrayRef[CodeBlock()];

coerce 'RepeatedCodeBlock',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::CodeBlock::CodeBlock'->new($_) } @$_ ] };

declare 'MapStringCodeBlock',
    as HashRef[CodeBlock()];

1;

__END__

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3beta1::CodeBlock::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
