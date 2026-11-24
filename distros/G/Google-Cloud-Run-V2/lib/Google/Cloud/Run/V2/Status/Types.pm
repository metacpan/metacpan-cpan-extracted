package Google::Cloud::Run::V2::Status::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'RevisionScalingStatus',
    as InstanceOf['Google::Cloud::Run::V2::Status::RevisionScalingStatus'];

coerce 'RevisionScalingStatus',
    from HashRef, via { 'Google::Cloud::Run::V2::Status::RevisionScalingStatus'->new($_) };

declare 'RepeatedRevisionScalingStatus',
    as ArrayRef[RevisionScalingStatus()];

coerce 'RepeatedRevisionScalingStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::Status::RevisionScalingStatus'->new($_) } @$_ ] };

declare 'MapStringRevisionScalingStatus',
    as HashRef[RevisionScalingStatus()];

1;

__END__

=head1 NAME

Google::Cloud::Run::V2::Status::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
