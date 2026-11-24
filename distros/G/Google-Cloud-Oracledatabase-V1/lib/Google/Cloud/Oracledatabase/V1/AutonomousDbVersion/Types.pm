package Google::Cloud::Oracledatabase::V1::AutonomousDbVersion::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AutonomousDbVersion',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::AutonomousDbVersion::AutonomousDbVersion'];

coerce 'AutonomousDbVersion',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::AutonomousDbVersion::AutonomousDbVersion'->new($_) };

declare 'RepeatedAutonomousDbVersion',
    as ArrayRef[AutonomousDbVersion()];

coerce 'RepeatedAutonomousDbVersion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::AutonomousDbVersion::AutonomousDbVersion'->new($_) } @$_ ] };

declare 'MapStringAutonomousDbVersion',
    as HashRef[AutonomousDbVersion()];

1;

__END__

=head1 NAME

Google::Cloud::Oracledatabase::V1::AutonomousDbVersion::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
