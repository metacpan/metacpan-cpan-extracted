package Google::Cloud::Talent::V4beta1::Job::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Job',
    as InstanceOf['Google::Cloud::Talent::V4beta1::Job::Job'];

coerce 'Job',
    from HashRef, via { 'Google::Cloud::Talent::V4beta1::Job::Job'->new($_) };

declare 'RepeatedJob',
    as ArrayRef[Job()];

coerce 'RepeatedJob',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Talent::V4beta1::Job::Job'->new($_) } @$_ ] };

declare 'MapStringJob',
    as HashRef[Job()];

declare 'ApplicationInfo',
    as InstanceOf['Google::Cloud::Talent::V4beta1::Job::Job::ApplicationInfo'];

coerce 'ApplicationInfo',
    from HashRef, via { 'Google::Cloud::Talent::V4beta1::Job::Job::ApplicationInfo'->new($_) };

declare 'RepeatedApplicationInfo',
    as ArrayRef[ApplicationInfo()];

coerce 'RepeatedApplicationInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Talent::V4beta1::Job::Job::ApplicationInfo'->new($_) } @$_ ] };

declare 'MapStringApplicationInfo',
    as HashRef[ApplicationInfo()];

declare 'DerivedInfo',
    as InstanceOf['Google::Cloud::Talent::V4beta1::Job::Job::DerivedInfo'];

coerce 'DerivedInfo',
    from HashRef, via { 'Google::Cloud::Talent::V4beta1::Job::Job::DerivedInfo'->new($_) };

declare 'RepeatedDerivedInfo',
    as ArrayRef[DerivedInfo()];

coerce 'RepeatedDerivedInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Talent::V4beta1::Job::Job::DerivedInfo'->new($_) } @$_ ] };

declare 'MapStringDerivedInfo',
    as HashRef[DerivedInfo()];

declare 'ProcessingOptions',
    as InstanceOf['Google::Cloud::Talent::V4beta1::Job::Job::ProcessingOptions'];

coerce 'ProcessingOptions',
    from HashRef, via { 'Google::Cloud::Talent::V4beta1::Job::Job::ProcessingOptions'->new($_) };

declare 'RepeatedProcessingOptions',
    as ArrayRef[ProcessingOptions()];

coerce 'RepeatedProcessingOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Talent::V4beta1::Job::Job::ProcessingOptions'->new($_) } @$_ ] };

declare 'MapStringProcessingOptions',
    as HashRef[ProcessingOptions()];

declare 'CustomAttributesEntry',
    as InstanceOf['Google::Cloud::Talent::V4beta1::Job::Job::CustomAttributesEntry'];

coerce 'CustomAttributesEntry',
    from HashRef, via { 'Google::Cloud::Talent::V4beta1::Job::Job::CustomAttributesEntry'->new($_) };

declare 'RepeatedCustomAttributesEntry',
    as ArrayRef[CustomAttributesEntry()];

coerce 'RepeatedCustomAttributesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Talent::V4beta1::Job::Job::CustomAttributesEntry'->new($_) } @$_ ] };

declare 'MapStringCustomAttributesEntry',
    as HashRef[CustomAttributesEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Talent::V4beta1::Job::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
