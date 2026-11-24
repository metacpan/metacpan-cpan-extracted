package Google::Cloud::Tasks::V2beta3::CmekConfig::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CmekConfig',
    as InstanceOf['Google::Cloud::Tasks::V2beta3::CmekConfig::CmekConfig'];

coerce 'CmekConfig',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta3::CmekConfig::CmekConfig'->new($_) };

declare 'RepeatedCmekConfig',
    as ArrayRef[CmekConfig()];

coerce 'RepeatedCmekConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta3::CmekConfig::CmekConfig'->new($_) } @$_ ] };

declare 'MapStringCmekConfig',
    as HashRef[CmekConfig()];

1;

__END__

=head1 NAME

Google::Cloud::Tasks::V2beta3::CmekConfig::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
