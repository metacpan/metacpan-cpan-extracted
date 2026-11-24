package Google::Cloud::Run::V2::TaskTemplate::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'TaskTemplate',
    as InstanceOf['Google::Cloud::Run::V2::TaskTemplate::TaskTemplate'];

coerce 'TaskTemplate',
    from HashRef, via { 'Google::Cloud::Run::V2::TaskTemplate::TaskTemplate'->new($_) };

declare 'RepeatedTaskTemplate',
    as ArrayRef[TaskTemplate()];

coerce 'RepeatedTaskTemplate',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::TaskTemplate::TaskTemplate'->new($_) } @$_ ] };

declare 'MapStringTaskTemplate',
    as HashRef[TaskTemplate()];

1;

__END__

=head1 NAME

Google::Cloud::Run::V2::TaskTemplate::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
