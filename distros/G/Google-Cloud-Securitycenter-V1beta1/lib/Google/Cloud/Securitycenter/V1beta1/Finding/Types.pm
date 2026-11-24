package Google::Cloud::Securitycenter::V1beta1::Finding::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Finding',
    as InstanceOf['Google::Cloud::Securitycenter::V1beta1::Finding::Finding'];

coerce 'Finding',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1beta1::Finding::Finding'->new($_) };

declare 'RepeatedFinding',
    as ArrayRef[Finding()];

coerce 'RepeatedFinding',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1beta1::Finding::Finding'->new($_) } @$_ ] };

declare 'MapStringFinding',
    as HashRef[Finding()];

declare 'State',
    as (Int | Str);

declare 'SourcePropertiesEntry',
    as InstanceOf['Google::Cloud::Securitycenter::V1beta1::Finding::Finding::SourcePropertiesEntry'];

coerce 'SourcePropertiesEntry',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1beta1::Finding::Finding::SourcePropertiesEntry'->new($_) };

declare 'RepeatedSourcePropertiesEntry',
    as ArrayRef[SourcePropertiesEntry()];

coerce 'RepeatedSourcePropertiesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1beta1::Finding::Finding::SourcePropertiesEntry'->new($_) } @$_ ] };

declare 'MapStringSourcePropertiesEntry',
    as HashRef[SourcePropertiesEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Securitycenter::V1beta1::Finding::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
