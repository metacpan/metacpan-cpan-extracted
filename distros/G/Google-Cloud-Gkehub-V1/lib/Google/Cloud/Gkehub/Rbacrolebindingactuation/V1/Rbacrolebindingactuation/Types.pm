package Google::Cloud::Gkehub::Rbacrolebindingactuation::V1::Rbacrolebindingactuation::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'FeatureSpec',
    as InstanceOf['Google::Cloud::Gkehub::Rbacrolebindingactuation::V1::Rbacrolebindingactuation::FeatureSpec'];

coerce 'FeatureSpec',
    from HashRef, via { 'Google::Cloud::Gkehub::Rbacrolebindingactuation::V1::Rbacrolebindingactuation::FeatureSpec'->new($_) };

declare 'RepeatedFeatureSpec',
    as ArrayRef[FeatureSpec()];

coerce 'RepeatedFeatureSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::Rbacrolebindingactuation::V1::Rbacrolebindingactuation::FeatureSpec'->new($_) } @$_ ] };

declare 'MapStringFeatureSpec',
    as HashRef[FeatureSpec()];

declare 'FeatureState',
    as InstanceOf['Google::Cloud::Gkehub::Rbacrolebindingactuation::V1::Rbacrolebindingactuation::FeatureState'];

coerce 'FeatureState',
    from HashRef, via { 'Google::Cloud::Gkehub::Rbacrolebindingactuation::V1::Rbacrolebindingactuation::FeatureState'->new($_) };

declare 'RepeatedFeatureState',
    as ArrayRef[FeatureState()];

coerce 'RepeatedFeatureState',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::Rbacrolebindingactuation::V1::Rbacrolebindingactuation::FeatureState'->new($_) } @$_ ] };

declare 'MapStringFeatureState',
    as HashRef[FeatureState()];

1;

__END__

=head1 NAME

Google::Cloud::Gkehub::Rbacrolebindingactuation::V1::Rbacrolebindingactuation::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
