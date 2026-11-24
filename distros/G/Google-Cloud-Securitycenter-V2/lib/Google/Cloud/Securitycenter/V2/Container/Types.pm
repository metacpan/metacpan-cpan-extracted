package Google::Cloud::Securitycenter::V2::Container::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Container',
    as InstanceOf['Google::Cloud::Securitycenter::V2::Container::Container'];

coerce 'Container',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::Container::Container'->new($_) };

declare 'RepeatedContainer',
    as ArrayRef[Container()];

coerce 'RepeatedContainer',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::Container::Container'->new($_) } @$_ ] };

declare 'MapStringContainer',
    as HashRef[Container()];

1;

__END__

=head1 NAME

Google::Cloud::Securitycenter::V2::Container::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
