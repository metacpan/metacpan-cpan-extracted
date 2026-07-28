package Google::Api::Visibility::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Visibility',
    as InstanceOf['Google::Api::Visibility::Visibility'];

coerce 'Visibility',
    from HashRef, via { 'Google::Api::Visibility::Visibility'->new($_) };

declare 'RepeatedVisibility',
    as ArrayRef[Visibility()];

coerce 'RepeatedVisibility',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Visibility::Visibility'->new($_) } @$_ ] };

declare 'MapStringVisibility',
    as HashRef[Visibility()];

declare 'VisibilityRule',
    as InstanceOf['Google::Api::Visibility::VisibilityRule'];

coerce 'VisibilityRule',
    from HashRef, via { 'Google::Api::Visibility::VisibilityRule'->new($_) };

declare 'RepeatedVisibilityRule',
    as ArrayRef[VisibilityRule()];

coerce 'RepeatedVisibilityRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Visibility::VisibilityRule'->new($_) } @$_ ] };

declare 'MapStringVisibilityRule',
    as HashRef[VisibilityRule()];

1;

__END__

=head1 NAME

Google::Api::Visibility::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
