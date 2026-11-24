package Google::Actions::Sdk::V2::Files::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Files',
    as InstanceOf['Google::Actions::Sdk::V2::Files::Files'];

coerce 'Files',
    from HashRef, via { 'Google::Actions::Sdk::V2::Files::Files'->new($_) };

declare 'RepeatedFiles',
    as ArrayRef[Files()];

coerce 'RepeatedFiles',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Files::Files'->new($_) } @$_ ] };

declare 'MapStringFiles',
    as HashRef[Files()];

1;

__END__

=head1 NAME

Google::Actions::Sdk::V2::Files::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
