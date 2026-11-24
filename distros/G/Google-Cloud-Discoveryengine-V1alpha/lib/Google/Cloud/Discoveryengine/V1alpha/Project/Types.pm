package Google::Cloud::Discoveryengine::V1alpha::Project::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Project',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::Project::Project'];

coerce 'Project',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::Project::Project'->new($_) };

declare 'RepeatedProject',
    as ArrayRef[Project()];

coerce 'RepeatedProject',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::Project::Project'->new($_) } @$_ ] };

declare 'MapStringProject',
    as HashRef[Project()];

declare 'ServiceTerms',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::Project::Project::ServiceTerms'];

coerce 'ServiceTerms',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::Project::Project::ServiceTerms'->new($_) };

declare 'RepeatedServiceTerms',
    as ArrayRef[ServiceTerms()];

coerce 'RepeatedServiceTerms',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::Project::Project::ServiceTerms'->new($_) } @$_ ] };

declare 'MapStringServiceTerms',
    as HashRef[ServiceTerms()];

declare 'State',
    as (Int | Str);

declare 'ServiceTermsMapEntry',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::Project::Project::ServiceTermsMapEntry'];

coerce 'ServiceTermsMapEntry',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::Project::Project::ServiceTermsMapEntry'->new($_) };

declare 'RepeatedServiceTermsMapEntry',
    as ArrayRef[ServiceTermsMapEntry()];

coerce 'RepeatedServiceTermsMapEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::Project::Project::ServiceTermsMapEntry'->new($_) } @$_ ] };

declare 'MapStringServiceTermsMapEntry',
    as HashRef[ServiceTermsMapEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1alpha::Project::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
