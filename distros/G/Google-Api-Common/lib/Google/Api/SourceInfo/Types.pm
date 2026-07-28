package Google::Api::SourceInfo::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SourceInfo',
    as InstanceOf['Google::Api::SourceInfo::SourceInfo'];

coerce 'SourceInfo',
    from HashRef, via { 'Google::Api::SourceInfo::SourceInfo'->new($_) };

declare 'RepeatedSourceInfo',
    as ArrayRef[SourceInfo()];

coerce 'RepeatedSourceInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::SourceInfo::SourceInfo'->new($_) } @$_ ] };

declare 'MapStringSourceInfo',
    as HashRef[SourceInfo()];

1;

__END__

=head1 NAME

Google::Api::SourceInfo::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
