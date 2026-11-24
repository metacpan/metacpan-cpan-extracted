package Google::Cloud::Securitycenter::V1::Notebook::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Notebook',
    as InstanceOf['Google::Cloud::Securitycenter::V1::Notebook::Notebook'];

coerce 'Notebook',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::Notebook::Notebook'->new($_) };

declare 'RepeatedNotebook',
    as ArrayRef[Notebook()];

coerce 'RepeatedNotebook',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::Notebook::Notebook'->new($_) } @$_ ] };

declare 'MapStringNotebook',
    as HashRef[Notebook()];

1;

__END__

=head1 NAME

Google::Cloud::Securitycenter::V1::Notebook::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
