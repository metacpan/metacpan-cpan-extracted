package Google::Cloud::Securitycenter::V1::Folder::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Folder',
    as InstanceOf['Google::Cloud::Securitycenter::V1::Folder::Folder'];

coerce 'Folder',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::Folder::Folder'->new($_) };

declare 'RepeatedFolder',
    as ArrayRef[Folder()];

coerce 'RepeatedFolder',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::Folder::Folder'->new($_) } @$_ ] };

declare 'MapStringFolder',
    as HashRef[Folder()];

1;

__END__

=head1 NAME

Google::Cloud::Securitycenter::V1::Folder::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
