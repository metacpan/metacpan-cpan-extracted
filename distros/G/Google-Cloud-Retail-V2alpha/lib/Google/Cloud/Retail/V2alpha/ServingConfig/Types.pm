package Google::Cloud::Retail::V2alpha::ServingConfig::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ServingConfig',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ServingConfig::ServingConfig'];

coerce 'ServingConfig',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ServingConfig::ServingConfig'->new($_) };

declare 'RepeatedServingConfig',
    as ArrayRef[ServingConfig()];

coerce 'RepeatedServingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ServingConfig::ServingConfig'->new($_) } @$_ ] };

declare 'MapStringServingConfig',
    as HashRef[ServingConfig()];

declare 'DiversityType',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Retail::V2alpha::ServingConfig::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
