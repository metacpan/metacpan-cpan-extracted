package Google::Actions::Sdk::V2::AccountLinkingSecret::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AccountLinkingSecret',
    as InstanceOf['Google::Actions::Sdk::V2::AccountLinkingSecret::AccountLinkingSecret'];

coerce 'AccountLinkingSecret',
    from HashRef, via { 'Google::Actions::Sdk::V2::AccountLinkingSecret::AccountLinkingSecret'->new($_) };

declare 'RepeatedAccountLinkingSecret',
    as ArrayRef[AccountLinkingSecret()];

coerce 'RepeatedAccountLinkingSecret',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::AccountLinkingSecret::AccountLinkingSecret'->new($_) } @$_ ] };

declare 'MapStringAccountLinkingSecret',
    as HashRef[AccountLinkingSecret()];

1;

__END__

=head1 NAME

Google::Actions::Sdk::V2::AccountLinkingSecret::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
