package Google::Cloud::Retail::V2beta::Project::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AlertConfig',
    as InstanceOf['Google::Cloud::Retail::V2beta::Project::AlertConfig'];

coerce 'AlertConfig',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::Project::AlertConfig'->new($_) };

declare 'RepeatedAlertConfig',
    as ArrayRef[AlertConfig()];

coerce 'RepeatedAlertConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::Project::AlertConfig'->new($_) } @$_ ] };

declare 'MapStringAlertConfig',
    as HashRef[AlertConfig()];

declare 'AlertPolicy',
    as InstanceOf['Google::Cloud::Retail::V2beta::Project::AlertConfig::AlertPolicy'];

coerce 'AlertPolicy',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::Project::AlertConfig::AlertPolicy'->new($_) };

declare 'RepeatedAlertPolicy',
    as ArrayRef[AlertPolicy()];

coerce 'RepeatedAlertPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::Project::AlertConfig::AlertPolicy'->new($_) } @$_ ] };

declare 'MapStringAlertPolicy',
    as HashRef[AlertPolicy()];

declare 'EnrollStatus',
    as (Int | Str);

declare 'Recipient',
    as InstanceOf['Google::Cloud::Retail::V2beta::Project::AlertConfig::AlertPolicy::Recipient'];

coerce 'Recipient',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::Project::AlertConfig::AlertPolicy::Recipient'->new($_) };

declare 'RepeatedRecipient',
    as ArrayRef[Recipient()];

coerce 'RepeatedRecipient',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::Project::AlertConfig::AlertPolicy::Recipient'->new($_) } @$_ ] };

declare 'MapStringRecipient',
    as HashRef[Recipient()];

1;

__END__

=head1 NAME

Google::Cloud::Retail::V2beta::Project::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
