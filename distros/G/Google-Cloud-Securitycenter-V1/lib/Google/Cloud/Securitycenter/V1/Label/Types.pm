package Google::Cloud::Securitycenter::V1::Label::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Label',
    as InstanceOf['Google::Cloud::Securitycenter::V1::Label::Label'];

coerce 'Label',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::Label::Label'->new($_) };

declare 'RepeatedLabel',
    as ArrayRef[Label()];

coerce 'RepeatedLabel',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::Label::Label'->new($_) } @$_ ] };

declare 'MapStringLabel',
    as HashRef[Label()];

1;

__END__

=head1 NAME

Google::Cloud::Securitycenter::V1::Label::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
