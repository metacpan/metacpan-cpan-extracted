package Google::Cloud::Securitycenter::V2::MuteConfig::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'MuteConfig',
    as InstanceOf['Google::Cloud::Securitycenter::V2::MuteConfig::MuteConfig'];

coerce 'MuteConfig',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::MuteConfig::MuteConfig'->new($_) };

declare 'RepeatedMuteConfig',
    as ArrayRef[MuteConfig()];

coerce 'RepeatedMuteConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::MuteConfig::MuteConfig'->new($_) } @$_ ] };

declare 'MapStringMuteConfig',
    as HashRef[MuteConfig()];

declare 'MuteConfigType',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Securitycenter::V2::MuteConfig::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
