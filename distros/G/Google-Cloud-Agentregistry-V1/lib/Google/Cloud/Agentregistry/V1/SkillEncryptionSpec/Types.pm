package Google::Cloud::Agentregistry::V1::SkillEncryptionSpec::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SkillEncryptionSpec',
    as InstanceOf['Google::Cloud::Agentregistry::V1::SkillEncryptionSpec::SkillEncryptionSpec'];

coerce 'SkillEncryptionSpec',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::SkillEncryptionSpec::SkillEncryptionSpec'->new($_) };

declare 'RepeatedSkillEncryptionSpec',
    as ArrayRef[SkillEncryptionSpec()];

coerce 'RepeatedSkillEncryptionSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::SkillEncryptionSpec::SkillEncryptionSpec'->new($_) } @$_ ] };

declare 'MapStringSkillEncryptionSpec',
    as HashRef[SkillEncryptionSpec()];

1;

__END__

=head1 NAME

Google::Cloud::Agentregistry::V1::SkillEncryptionSpec::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
