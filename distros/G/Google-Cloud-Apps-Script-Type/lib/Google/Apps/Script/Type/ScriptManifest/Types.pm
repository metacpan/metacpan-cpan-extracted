package Google::Apps::Script::Type::ScriptManifest::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'HttpAuthorizationHeader',
    as (Int | Str);

declare 'CommonAddOnManifest',
    as InstanceOf['Google::Apps::Script::Type::ScriptManifest::CommonAddOnManifest'];

coerce 'CommonAddOnManifest',
    from HashRef, via { 'Google::Apps::Script::Type::ScriptManifest::CommonAddOnManifest'->new($_) };

declare 'RepeatedCommonAddOnManifest',
    as ArrayRef[CommonAddOnManifest()];

coerce 'RepeatedCommonAddOnManifest',
    from ArrayRef[HashRef], via { [ map { 'Google::Apps::Script::Type::ScriptManifest::CommonAddOnManifest'->new($_) } @$_ ] };

declare 'MapStringCommonAddOnManifest',
    as HashRef[CommonAddOnManifest()];

declare 'LayoutProperties',
    as InstanceOf['Google::Apps::Script::Type::ScriptManifest::LayoutProperties'];

coerce 'LayoutProperties',
    from HashRef, via { 'Google::Apps::Script::Type::ScriptManifest::LayoutProperties'->new($_) };

declare 'RepeatedLayoutProperties',
    as ArrayRef[LayoutProperties()];

coerce 'RepeatedLayoutProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Apps::Script::Type::ScriptManifest::LayoutProperties'->new($_) } @$_ ] };

declare 'MapStringLayoutProperties',
    as HashRef[LayoutProperties()];

declare 'HttpOptions',
    as InstanceOf['Google::Apps::Script::Type::ScriptManifest::HttpOptions'];

coerce 'HttpOptions',
    from HashRef, via { 'Google::Apps::Script::Type::ScriptManifest::HttpOptions'->new($_) };

declare 'RepeatedHttpOptions',
    as ArrayRef[HttpOptions()];

coerce 'RepeatedHttpOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Apps::Script::Type::ScriptManifest::HttpOptions'->new($_) } @$_ ] };

declare 'MapStringHttpOptions',
    as HashRef[HttpOptions()];

1;

__END__

=head1 NAME

Google::Apps::Script::Type::ScriptManifest::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
