package Google::Cloud::Oracledatabase::V1::AutonomousDatabaseCharacterSet::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AutonomousDatabaseCharacterSet',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::AutonomousDatabaseCharacterSet::AutonomousDatabaseCharacterSet'];

coerce 'AutonomousDatabaseCharacterSet',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::AutonomousDatabaseCharacterSet::AutonomousDatabaseCharacterSet'->new($_) };

declare 'RepeatedAutonomousDatabaseCharacterSet',
    as ArrayRef[AutonomousDatabaseCharacterSet()];

coerce 'RepeatedAutonomousDatabaseCharacterSet',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::AutonomousDatabaseCharacterSet::AutonomousDatabaseCharacterSet'->new($_) } @$_ ] };

declare 'MapStringAutonomousDatabaseCharacterSet',
    as HashRef[AutonomousDatabaseCharacterSet()];

declare 'CharacterSetType',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Oracledatabase::V1::AutonomousDatabaseCharacterSet::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
