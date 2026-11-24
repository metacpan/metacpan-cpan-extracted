package Google::Cloud::Designcenter::V1::Authoring::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ApplicationTemplate',
    as InstanceOf['Google::Cloud::Designcenter::V1::Authoring::ApplicationTemplate'];

coerce 'ApplicationTemplate',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Authoring::ApplicationTemplate'->new($_) };

declare 'RepeatedApplicationTemplate',
    as ArrayRef[ApplicationTemplate()];

coerce 'RepeatedApplicationTemplate',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Authoring::ApplicationTemplate'->new($_) } @$_ ] };

declare 'MapStringApplicationTemplate',
    as HashRef[ApplicationTemplate()];

declare 'IACFormat',
    as (Int | Str);

declare 'SerializedApplicationTemplate',
    as InstanceOf['Google::Cloud::Designcenter::V1::Authoring::SerializedApplicationTemplate'];

coerce 'SerializedApplicationTemplate',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Authoring::SerializedApplicationTemplate'->new($_) };

declare 'RepeatedSerializedApplicationTemplate',
    as ArrayRef[SerializedApplicationTemplate()];

coerce 'RepeatedSerializedApplicationTemplate',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Authoring::SerializedApplicationTemplate'->new($_) } @$_ ] };

declare 'MapStringSerializedApplicationTemplate',
    as HashRef[SerializedApplicationTemplate()];

declare 'AppHubApplicationParameters',
    as InstanceOf['Google::Cloud::Designcenter::V1::Authoring::AppHubApplicationParameters'];

coerce 'AppHubApplicationParameters',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Authoring::AppHubApplicationParameters'->new($_) };

declare 'RepeatedAppHubApplicationParameters',
    as ArrayRef[AppHubApplicationParameters()];

coerce 'RepeatedAppHubApplicationParameters',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Authoring::AppHubApplicationParameters'->new($_) } @$_ ] };

declare 'MapStringAppHubApplicationParameters',
    as HashRef[AppHubApplicationParameters()];

declare 'InputVariableAlias',
    as InstanceOf['Google::Cloud::Designcenter::V1::Authoring::InputVariableAlias'];

coerce 'InputVariableAlias',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Authoring::InputVariableAlias'->new($_) };

declare 'RepeatedInputVariableAlias',
    as ArrayRef[InputVariableAlias()];

coerce 'RepeatedInputVariableAlias',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Authoring::InputVariableAlias'->new($_) } @$_ ] };

declare 'MapStringInputVariableAlias',
    as HashRef[InputVariableAlias()];

declare 'SerializedComponent',
    as InstanceOf['Google::Cloud::Designcenter::V1::Authoring::SerializedComponent'];

coerce 'SerializedComponent',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Authoring::SerializedComponent'->new($_) };

declare 'RepeatedSerializedComponent',
    as ArrayRef[SerializedComponent()];

coerce 'RepeatedSerializedComponent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Authoring::SerializedComponent'->new($_) } @$_ ] };

declare 'MapStringSerializedComponent',
    as HashRef[SerializedComponent()];

declare 'SerializedConnection',
    as InstanceOf['Google::Cloud::Designcenter::V1::Authoring::SerializedConnection'];

coerce 'SerializedConnection',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Authoring::SerializedConnection'->new($_) };

declare 'RepeatedSerializedConnection',
    as ArrayRef[SerializedConnection()];

coerce 'RepeatedSerializedConnection',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Authoring::SerializedConnection'->new($_) } @$_ ] };

declare 'MapStringSerializedConnection',
    as HashRef[SerializedConnection()];

declare 'SerializedPolicy',
    as InstanceOf['Google::Cloud::Designcenter::V1::Authoring::SerializedPolicy'];

coerce 'SerializedPolicy',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Authoring::SerializedPolicy'->new($_) };

declare 'RepeatedSerializedPolicy',
    as ArrayRef[SerializedPolicy()];

coerce 'RepeatedSerializedPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Authoring::SerializedPolicy'->new($_) } @$_ ] };

declare 'MapStringSerializedPolicy',
    as HashRef[SerializedPolicy()];

declare 'PolicyType',
    as (Int | Str);

declare 'ApplicationTemplateRevision',
    as InstanceOf['Google::Cloud::Designcenter::V1::Authoring::ApplicationTemplateRevision'];

coerce 'ApplicationTemplateRevision',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Authoring::ApplicationTemplateRevision'->new($_) };

declare 'RepeatedApplicationTemplateRevision',
    as ArrayRef[ApplicationTemplateRevision()];

coerce 'RepeatedApplicationTemplateRevision',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Authoring::ApplicationTemplateRevision'->new($_) } @$_ ] };

declare 'MapStringApplicationTemplateRevision',
    as HashRef[ApplicationTemplateRevision()];

declare 'ApplicationTemplateSystemRevision',
    as InstanceOf['Google::Cloud::Designcenter::V1::Authoring::ApplicationTemplateSystemRevision'];

coerce 'ApplicationTemplateSystemRevision',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Authoring::ApplicationTemplateSystemRevision'->new($_) };

declare 'RepeatedApplicationTemplateSystemRevision',
    as ArrayRef[ApplicationTemplateSystemRevision()];

coerce 'RepeatedApplicationTemplateSystemRevision',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Authoring::ApplicationTemplateSystemRevision'->new($_) } @$_ ] };

declare 'MapStringApplicationTemplateSystemRevision',
    as HashRef[ApplicationTemplateSystemRevision()];

declare 'AnnotationsEntry',
    as InstanceOf['Google::Cloud::Designcenter::V1::Authoring::ApplicationTemplateSystemRevision::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Authoring::ApplicationTemplateSystemRevision::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Authoring::ApplicationTemplateSystemRevision::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

declare 'Component',
    as InstanceOf['Google::Cloud::Designcenter::V1::Authoring::Component'];

coerce 'Component',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Authoring::Component'->new($_) };

declare 'RepeatedComponent',
    as ArrayRef[Component()];

coerce 'RepeatedComponent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Authoring::Component'->new($_) } @$_ ] };

declare 'MapStringComponent',
    as HashRef[Component()];

declare 'Connection',
    as InstanceOf['Google::Cloud::Designcenter::V1::Authoring::Connection'];

coerce 'Connection',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Authoring::Connection'->new($_) };

declare 'RepeatedConnection',
    as ArrayRef[Connection()];

coerce 'RepeatedConnection',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Authoring::Connection'->new($_) } @$_ ] };

declare 'MapStringConnection',
    as HashRef[Connection()];

declare 'SerializedProvider',
    as InstanceOf['Google::Cloud::Designcenter::V1::Authoring::SerializedProvider'];

coerce 'SerializedProvider',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Authoring::SerializedProvider'->new($_) };

declare 'RepeatedSerializedProvider',
    as ArrayRef[SerializedProvider()];

coerce 'RepeatedSerializedProvider',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Authoring::SerializedProvider'->new($_) } @$_ ] };

declare 'MapStringSerializedProvider',
    as HashRef[SerializedProvider()];

1;

__END__

=head1 NAME

Google::Cloud::Designcenter::V1::Authoring::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
