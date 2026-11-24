package Google::Cloud::Websecurityscanner::V1::FindingAddon::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Form',
    as InstanceOf['Google::Cloud::Websecurityscanner::V1::FindingAddon::Form'];

coerce 'Form',
    from HashRef, via { 'Google::Cloud::Websecurityscanner::V1::FindingAddon::Form'->new($_) };

declare 'RepeatedForm',
    as ArrayRef[Form()];

coerce 'RepeatedForm',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Websecurityscanner::V1::FindingAddon::Form'->new($_) } @$_ ] };

declare 'MapStringForm',
    as HashRef[Form()];

declare 'OutdatedLibrary',
    as InstanceOf['Google::Cloud::Websecurityscanner::V1::FindingAddon::OutdatedLibrary'];

coerce 'OutdatedLibrary',
    from HashRef, via { 'Google::Cloud::Websecurityscanner::V1::FindingAddon::OutdatedLibrary'->new($_) };

declare 'RepeatedOutdatedLibrary',
    as ArrayRef[OutdatedLibrary()];

coerce 'RepeatedOutdatedLibrary',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Websecurityscanner::V1::FindingAddon::OutdatedLibrary'->new($_) } @$_ ] };

declare 'MapStringOutdatedLibrary',
    as HashRef[OutdatedLibrary()];

declare 'ViolatingResource',
    as InstanceOf['Google::Cloud::Websecurityscanner::V1::FindingAddon::ViolatingResource'];

coerce 'ViolatingResource',
    from HashRef, via { 'Google::Cloud::Websecurityscanner::V1::FindingAddon::ViolatingResource'->new($_) };

declare 'RepeatedViolatingResource',
    as ArrayRef[ViolatingResource()];

coerce 'RepeatedViolatingResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Websecurityscanner::V1::FindingAddon::ViolatingResource'->new($_) } @$_ ] };

declare 'MapStringViolatingResource',
    as HashRef[ViolatingResource()];

declare 'VulnerableParameters',
    as InstanceOf['Google::Cloud::Websecurityscanner::V1::FindingAddon::VulnerableParameters'];

coerce 'VulnerableParameters',
    from HashRef, via { 'Google::Cloud::Websecurityscanner::V1::FindingAddon::VulnerableParameters'->new($_) };

declare 'RepeatedVulnerableParameters',
    as ArrayRef[VulnerableParameters()];

coerce 'RepeatedVulnerableParameters',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Websecurityscanner::V1::FindingAddon::VulnerableParameters'->new($_) } @$_ ] };

declare 'MapStringVulnerableParameters',
    as HashRef[VulnerableParameters()];

declare 'VulnerableHeaders',
    as InstanceOf['Google::Cloud::Websecurityscanner::V1::FindingAddon::VulnerableHeaders'];

coerce 'VulnerableHeaders',
    from HashRef, via { 'Google::Cloud::Websecurityscanner::V1::FindingAddon::VulnerableHeaders'->new($_) };

declare 'RepeatedVulnerableHeaders',
    as ArrayRef[VulnerableHeaders()];

coerce 'RepeatedVulnerableHeaders',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Websecurityscanner::V1::FindingAddon::VulnerableHeaders'->new($_) } @$_ ] };

declare 'MapStringVulnerableHeaders',
    as HashRef[VulnerableHeaders()];

declare 'Header',
    as InstanceOf['Google::Cloud::Websecurityscanner::V1::FindingAddon::VulnerableHeaders::Header'];

coerce 'Header',
    from HashRef, via { 'Google::Cloud::Websecurityscanner::V1::FindingAddon::VulnerableHeaders::Header'->new($_) };

declare 'RepeatedHeader',
    as ArrayRef[Header()];

coerce 'RepeatedHeader',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Websecurityscanner::V1::FindingAddon::VulnerableHeaders::Header'->new($_) } @$_ ] };

declare 'MapStringHeader',
    as HashRef[Header()];

declare 'Xss',
    as InstanceOf['Google::Cloud::Websecurityscanner::V1::FindingAddon::Xss'];

coerce 'Xss',
    from HashRef, via { 'Google::Cloud::Websecurityscanner::V1::FindingAddon::Xss'->new($_) };

declare 'RepeatedXss',
    as ArrayRef[Xss()];

coerce 'RepeatedXss',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Websecurityscanner::V1::FindingAddon::Xss'->new($_) } @$_ ] };

declare 'MapStringXss',
    as HashRef[Xss()];

declare 'AttackVector',
    as (Int | Str);

declare 'Xxe',
    as InstanceOf['Google::Cloud::Websecurityscanner::V1::FindingAddon::Xxe'];

coerce 'Xxe',
    from HashRef, via { 'Google::Cloud::Websecurityscanner::V1::FindingAddon::Xxe'->new($_) };

declare 'RepeatedXxe',
    as ArrayRef[Xxe()];

coerce 'RepeatedXxe',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Websecurityscanner::V1::FindingAddon::Xxe'->new($_) } @$_ ] };

declare 'MapStringXxe',
    as HashRef[Xxe()];

declare 'Location',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Websecurityscanner::V1::FindingAddon::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
