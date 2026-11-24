package Google::Cloud::Support::V2beta::EmailMessage::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'EmailMessage',
    as InstanceOf['Google::Cloud::Support::V2beta::EmailMessage::EmailMessage'];

coerce 'EmailMessage',
    from HashRef, via { 'Google::Cloud::Support::V2beta::EmailMessage::EmailMessage'->new($_) };

declare 'RepeatedEmailMessage',
    as ArrayRef[EmailMessage()];

coerce 'RepeatedEmailMessage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Support::V2beta::EmailMessage::EmailMessage'->new($_) } @$_ ] };

declare 'MapStringEmailMessage',
    as HashRef[EmailMessage()];

1;

__END__

=head1 NAME

Google::Cloud::Support::V2beta::EmailMessage::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
