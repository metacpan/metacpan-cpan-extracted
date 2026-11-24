package Google::Cloud::Securitycenter::V1::ContactDetails::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ContactDetails',
    as InstanceOf['Google::Cloud::Securitycenter::V1::ContactDetails::ContactDetails'];

coerce 'ContactDetails',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::ContactDetails::ContactDetails'->new($_) };

declare 'RepeatedContactDetails',
    as ArrayRef[ContactDetails()];

coerce 'RepeatedContactDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::ContactDetails::ContactDetails'->new($_) } @$_ ] };

declare 'MapStringContactDetails',
    as HashRef[ContactDetails()];

declare 'Contact',
    as InstanceOf['Google::Cloud::Securitycenter::V1::ContactDetails::Contact'];

coerce 'Contact',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::ContactDetails::Contact'->new($_) };

declare 'RepeatedContact',
    as ArrayRef[Contact()];

coerce 'RepeatedContact',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::ContactDetails::Contact'->new($_) } @$_ ] };

declare 'MapStringContact',
    as HashRef[Contact()];

1;

__END__

=head1 NAME

Google::Cloud::Securitycenter::V1::ContactDetails::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
