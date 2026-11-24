package Google::Cloud::Securitycenter::V2::AffectedResources::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AffectedResources',
    as InstanceOf['Google::Cloud::Securitycenter::V2::AffectedResources::AffectedResources'];

coerce 'AffectedResources',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::AffectedResources::AffectedResources'->new($_) };

declare 'RepeatedAffectedResources',
    as ArrayRef[AffectedResources()];

coerce 'RepeatedAffectedResources',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::AffectedResources::AffectedResources'->new($_) } @$_ ] };

declare 'MapStringAffectedResources',
    as HashRef[AffectedResources()];

1;

__END__

=head1 NAME

Google::Cloud::Securitycenter::V2::AffectedResources::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
