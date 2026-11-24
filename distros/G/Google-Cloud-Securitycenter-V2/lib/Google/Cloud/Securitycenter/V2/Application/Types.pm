package Google::Cloud::Securitycenter::V2::Application::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Application',
    as InstanceOf['Google::Cloud::Securitycenter::V2::Application::Application'];

coerce 'Application',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::Application::Application'->new($_) };

declare 'RepeatedApplication',
    as ArrayRef[Application()];

coerce 'RepeatedApplication',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::Application::Application'->new($_) } @$_ ] };

declare 'MapStringApplication',
    as HashRef[Application()];

1;

__END__

=head1 NAME

Google::Cloud::Securitycenter::V2::Application::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
