package Google::Cloud::Baremetalsolution::V2::SshKey::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SSHKey',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::SshKey::SSHKey'];

coerce 'SSHKey',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::SshKey::SSHKey'->new($_) };

declare 'RepeatedSSHKey',
    as ArrayRef[SSHKey()];

coerce 'RepeatedSSHKey',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::SshKey::SSHKey'->new($_) } @$_ ] };

declare 'MapStringSSHKey',
    as HashRef[SSHKey()];

declare 'ListSSHKeysRequest',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::SshKey::ListSSHKeysRequest'];

coerce 'ListSSHKeysRequest',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::SshKey::ListSSHKeysRequest'->new($_) };

declare 'RepeatedListSSHKeysRequest',
    as ArrayRef[ListSSHKeysRequest()];

coerce 'RepeatedListSSHKeysRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::SshKey::ListSSHKeysRequest'->new($_) } @$_ ] };

declare 'MapStringListSSHKeysRequest',
    as HashRef[ListSSHKeysRequest()];

declare 'ListSSHKeysResponse',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::SshKey::ListSSHKeysResponse'];

coerce 'ListSSHKeysResponse',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::SshKey::ListSSHKeysResponse'->new($_) };

declare 'RepeatedListSSHKeysResponse',
    as ArrayRef[ListSSHKeysResponse()];

coerce 'RepeatedListSSHKeysResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::SshKey::ListSSHKeysResponse'->new($_) } @$_ ] };

declare 'MapStringListSSHKeysResponse',
    as HashRef[ListSSHKeysResponse()];

declare 'CreateSSHKeyRequest',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::SshKey::CreateSSHKeyRequest'];

coerce 'CreateSSHKeyRequest',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::SshKey::CreateSSHKeyRequest'->new($_) };

declare 'RepeatedCreateSSHKeyRequest',
    as ArrayRef[CreateSSHKeyRequest()];

coerce 'RepeatedCreateSSHKeyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::SshKey::CreateSSHKeyRequest'->new($_) } @$_ ] };

declare 'MapStringCreateSSHKeyRequest',
    as HashRef[CreateSSHKeyRequest()];

declare 'DeleteSSHKeyRequest',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::SshKey::DeleteSSHKeyRequest'];

coerce 'DeleteSSHKeyRequest',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::SshKey::DeleteSSHKeyRequest'->new($_) };

declare 'RepeatedDeleteSSHKeyRequest',
    as ArrayRef[DeleteSSHKeyRequest()];

coerce 'RepeatedDeleteSSHKeyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::SshKey::DeleteSSHKeyRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteSSHKeyRequest',
    as HashRef[DeleteSSHKeyRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Baremetalsolution::V2::SshKey::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
