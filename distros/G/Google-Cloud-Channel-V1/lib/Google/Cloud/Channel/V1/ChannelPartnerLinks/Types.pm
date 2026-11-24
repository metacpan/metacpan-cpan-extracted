package Google::Cloud::Channel::V1::ChannelPartnerLinks::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ChannelPartnerLinkView',
    as (Int | Str);

declare 'ChannelPartnerLinkState',
    as (Int | Str);

declare 'ChannelPartnerLink',
    as InstanceOf['Google::Cloud::Channel::V1::ChannelPartnerLinks::ChannelPartnerLink'];

coerce 'ChannelPartnerLink',
    from HashRef, via { 'Google::Cloud::Channel::V1::ChannelPartnerLinks::ChannelPartnerLink'->new($_) };

declare 'RepeatedChannelPartnerLink',
    as ArrayRef[ChannelPartnerLink()];

coerce 'RepeatedChannelPartnerLink',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::ChannelPartnerLinks::ChannelPartnerLink'->new($_) } @$_ ] };

declare 'MapStringChannelPartnerLink',
    as HashRef[ChannelPartnerLink()];

1;

__END__

=head1 NAME

Google::Cloud::Channel::V1::ChannelPartnerLinks::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
