package Google::Cloud::Cloudcontrolspartner::V1::Violations::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Violation',
    as InstanceOf['Google::Cloud::Cloudcontrolspartner::V1::Violations::Violation'];

coerce 'Violation',
    from HashRef, via { 'Google::Cloud::Cloudcontrolspartner::V1::Violations::Violation'->new($_) };

declare 'RepeatedViolation',
    as ArrayRef[Violation()];

coerce 'RepeatedViolation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudcontrolspartner::V1::Violations::Violation'->new($_) } @$_ ] };

declare 'MapStringViolation',
    as HashRef[Violation()];

declare 'State',
    as (Int | Str);

declare 'Remediation',
    as InstanceOf['Google::Cloud::Cloudcontrolspartner::V1::Violations::Violation::Remediation'];

coerce 'Remediation',
    from HashRef, via { 'Google::Cloud::Cloudcontrolspartner::V1::Violations::Violation::Remediation'->new($_) };

declare 'RepeatedRemediation',
    as ArrayRef[Remediation()];

coerce 'RepeatedRemediation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudcontrolspartner::V1::Violations::Violation::Remediation'->new($_) } @$_ ] };

declare 'MapStringRemediation',
    as HashRef[Remediation()];

declare 'RemediationType',
    as (Int | Str);

declare 'Instructions',
    as InstanceOf['Google::Cloud::Cloudcontrolspartner::V1::Violations::Violation::Remediation::Instructions'];

coerce 'Instructions',
    from HashRef, via { 'Google::Cloud::Cloudcontrolspartner::V1::Violations::Violation::Remediation::Instructions'->new($_) };

declare 'RepeatedInstructions',
    as ArrayRef[Instructions()];

coerce 'RepeatedInstructions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudcontrolspartner::V1::Violations::Violation::Remediation::Instructions'->new($_) } @$_ ] };

declare 'MapStringInstructions',
    as HashRef[Instructions()];

declare 'Gcloud',
    as InstanceOf['Google::Cloud::Cloudcontrolspartner::V1::Violations::Violation::Remediation::Instructions::Gcloud'];

coerce 'Gcloud',
    from HashRef, via { 'Google::Cloud::Cloudcontrolspartner::V1::Violations::Violation::Remediation::Instructions::Gcloud'->new($_) };

declare 'RepeatedGcloud',
    as ArrayRef[Gcloud()];

coerce 'RepeatedGcloud',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudcontrolspartner::V1::Violations::Violation::Remediation::Instructions::Gcloud'->new($_) } @$_ ] };

declare 'MapStringGcloud',
    as HashRef[Gcloud()];

declare 'Console',
    as InstanceOf['Google::Cloud::Cloudcontrolspartner::V1::Violations::Violation::Remediation::Instructions::Console'];

coerce 'Console',
    from HashRef, via { 'Google::Cloud::Cloudcontrolspartner::V1::Violations::Violation::Remediation::Instructions::Console'->new($_) };

declare 'RepeatedConsole',
    as ArrayRef[Console()];

coerce 'RepeatedConsole',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudcontrolspartner::V1::Violations::Violation::Remediation::Instructions::Console'->new($_) } @$_ ] };

declare 'MapStringConsole',
    as HashRef[Console()];

declare 'ListViolationsRequest',
    as InstanceOf['Google::Cloud::Cloudcontrolspartner::V1::Violations::ListViolationsRequest'];

coerce 'ListViolationsRequest',
    from HashRef, via { 'Google::Cloud::Cloudcontrolspartner::V1::Violations::ListViolationsRequest'->new($_) };

declare 'RepeatedListViolationsRequest',
    as ArrayRef[ListViolationsRequest()];

coerce 'RepeatedListViolationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudcontrolspartner::V1::Violations::ListViolationsRequest'->new($_) } @$_ ] };

declare 'MapStringListViolationsRequest',
    as HashRef[ListViolationsRequest()];

declare 'ListViolationsResponse',
    as InstanceOf['Google::Cloud::Cloudcontrolspartner::V1::Violations::ListViolationsResponse'];

coerce 'ListViolationsResponse',
    from HashRef, via { 'Google::Cloud::Cloudcontrolspartner::V1::Violations::ListViolationsResponse'->new($_) };

declare 'RepeatedListViolationsResponse',
    as ArrayRef[ListViolationsResponse()];

coerce 'RepeatedListViolationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudcontrolspartner::V1::Violations::ListViolationsResponse'->new($_) } @$_ ] };

declare 'MapStringListViolationsResponse',
    as HashRef[ListViolationsResponse()];

declare 'GetViolationRequest',
    as InstanceOf['Google::Cloud::Cloudcontrolspartner::V1::Violations::GetViolationRequest'];

coerce 'GetViolationRequest',
    from HashRef, via { 'Google::Cloud::Cloudcontrolspartner::V1::Violations::GetViolationRequest'->new($_) };

declare 'RepeatedGetViolationRequest',
    as ArrayRef[GetViolationRequest()];

coerce 'RepeatedGetViolationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudcontrolspartner::V1::Violations::GetViolationRequest'->new($_) } @$_ ] };

declare 'MapStringGetViolationRequest',
    as HashRef[GetViolationRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Cloudcontrolspartner::V1::Violations::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
