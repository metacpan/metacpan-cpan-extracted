package Google::Cloud::Policytroubleshooter::V1::Checker::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'TroubleshootIamPolicyRequest',
    as InstanceOf['Google::Cloud::Policytroubleshooter::V1::Checker::TroubleshootIamPolicyRequest'];

coerce 'TroubleshootIamPolicyRequest',
    from HashRef, via { 'Google::Cloud::Policytroubleshooter::V1::Checker::TroubleshootIamPolicyRequest'->new($_) };

declare 'RepeatedTroubleshootIamPolicyRequest',
    as ArrayRef[TroubleshootIamPolicyRequest()];

coerce 'RepeatedTroubleshootIamPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Policytroubleshooter::V1::Checker::TroubleshootIamPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringTroubleshootIamPolicyRequest',
    as HashRef[TroubleshootIamPolicyRequest()];

declare 'TroubleshootIamPolicyResponse',
    as InstanceOf['Google::Cloud::Policytroubleshooter::V1::Checker::TroubleshootIamPolicyResponse'];

coerce 'TroubleshootIamPolicyResponse',
    from HashRef, via { 'Google::Cloud::Policytroubleshooter::V1::Checker::TroubleshootIamPolicyResponse'->new($_) };

declare 'RepeatedTroubleshootIamPolicyResponse',
    as ArrayRef[TroubleshootIamPolicyResponse()];

coerce 'RepeatedTroubleshootIamPolicyResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Policytroubleshooter::V1::Checker::TroubleshootIamPolicyResponse'->new($_) } @$_ ] };

declare 'MapStringTroubleshootIamPolicyResponse',
    as HashRef[TroubleshootIamPolicyResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Policytroubleshooter::V1::Checker::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
