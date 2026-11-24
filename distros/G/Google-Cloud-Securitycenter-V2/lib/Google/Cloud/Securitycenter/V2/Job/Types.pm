package Google::Cloud::Securitycenter::V2::Job::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'JobState',
    as (Int | Str);

declare 'Job',
    as InstanceOf['Google::Cloud::Securitycenter::V2::Job::Job'];

coerce 'Job',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::Job::Job'->new($_) };

declare 'RepeatedJob',
    as ArrayRef[Job()];

coerce 'RepeatedJob',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::Job::Job'->new($_) } @$_ ] };

declare 'MapStringJob',
    as HashRef[Job()];

1;

__END__

=head1 NAME

Google::Cloud::Securitycenter::V2::Job::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
