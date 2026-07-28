package Google::Cloud::Networksecurity::V1::SecurityProfileGroupIntercept::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CustomInterceptProfile',
    as InstanceOf['Google::Cloud::Networksecurity::V1::SecurityProfileGroupIntercept::CustomInterceptProfile'];

coerce 'CustomInterceptProfile',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::SecurityProfileGroupIntercept::CustomInterceptProfile'->new($_) };

declare 'RepeatedCustomInterceptProfile',
    as ArrayRef[CustomInterceptProfile()];

coerce 'RepeatedCustomInterceptProfile',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::SecurityProfileGroupIntercept::CustomInterceptProfile'->new($_) } @$_ ] };

declare 'MapStringCustomInterceptProfile',
    as HashRef[CustomInterceptProfile()];

1;

__END__

=head1 NAME

Google::Cloud::Networksecurity::V1::SecurityProfileGroupIntercept::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
