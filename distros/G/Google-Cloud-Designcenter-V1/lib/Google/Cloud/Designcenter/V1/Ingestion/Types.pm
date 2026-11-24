package Google::Cloud::Designcenter::V1::Ingestion::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GitSource',
    as InstanceOf['Google::Cloud::Designcenter::V1::Ingestion::GitSource'];

coerce 'GitSource',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Ingestion::GitSource'->new($_) };

declare 'RepeatedGitSource',
    as ArrayRef[GitSource()];

coerce 'RepeatedGitSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Ingestion::GitSource'->new($_) } @$_ ] };

declare 'MapStringGitSource',
    as HashRef[GitSource()];

declare 'DeveloperConnectConfig',
    as InstanceOf['Google::Cloud::Designcenter::V1::Ingestion::DeveloperConnectConfig'];

coerce 'DeveloperConnectConfig',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Ingestion::DeveloperConnectConfig'->new($_) };

declare 'RepeatedDeveloperConnectConfig',
    as ArrayRef[DeveloperConnectConfig()];

coerce 'RepeatedDeveloperConnectConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Ingestion::DeveloperConnectConfig'->new($_) } @$_ ] };

declare 'MapStringDeveloperConnectConfig',
    as HashRef[DeveloperConnectConfig()];

declare 'DeveloperConnectSourceConfig',
    as InstanceOf['Google::Cloud::Designcenter::V1::Ingestion::DeveloperConnectSourceConfig'];

coerce 'DeveloperConnectSourceConfig',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Ingestion::DeveloperConnectSourceConfig'->new($_) };

declare 'RepeatedDeveloperConnectSourceConfig',
    as ArrayRef[DeveloperConnectSourceConfig()];

coerce 'RepeatedDeveloperConnectSourceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Ingestion::DeveloperConnectSourceConfig'->new($_) } @$_ ] };

declare 'MapStringDeveloperConnectSourceConfig',
    as HashRef[DeveloperConnectSourceConfig()];

declare 'GitReference',
    as InstanceOf['Google::Cloud::Designcenter::V1::Ingestion::GitReference'];

coerce 'GitReference',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Ingestion::GitReference'->new($_) };

declare 'RepeatedGitReference',
    as ArrayRef[GitReference()];

coerce 'RepeatedGitReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Ingestion::GitReference'->new($_) } @$_ ] };

declare 'MapStringGitReference',
    as HashRef[GitReference()];

declare 'OciRepo',
    as InstanceOf['Google::Cloud::Designcenter::V1::Ingestion::OciRepo'];

coerce 'OciRepo',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Ingestion::OciRepo'->new($_) };

declare 'RepeatedOciRepo',
    as ArrayRef[OciRepo()];

coerce 'RepeatedOciRepo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Ingestion::OciRepo'->new($_) } @$_ ] };

declare 'MapStringOciRepo',
    as HashRef[OciRepo()];

declare 'IaCModule',
    as InstanceOf['Google::Cloud::Designcenter::V1::Ingestion::IaCModule'];

coerce 'IaCModule',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Ingestion::IaCModule'->new($_) };

declare 'RepeatedIaCModule',
    as ArrayRef[IaCModule()];

coerce 'RepeatedIaCModule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Ingestion::IaCModule'->new($_) } @$_ ] };

declare 'MapStringIaCModule',
    as HashRef[IaCModule()];

declare 'IaCFile',
    as InstanceOf['Google::Cloud::Designcenter::V1::Ingestion::IaCFile'];

coerce 'IaCFile',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Ingestion::IaCFile'->new($_) };

declare 'RepeatedIaCFile',
    as ArrayRef[IaCFile()];

coerce 'RepeatedIaCFile',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Ingestion::IaCFile'->new($_) } @$_ ] };

declare 'MapStringIaCFile',
    as HashRef[IaCFile()];

declare 'ImportIaCError',
    as InstanceOf['Google::Cloud::Designcenter::V1::Ingestion::ImportIaCError'];

coerce 'ImportIaCError',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Ingestion::ImportIaCError'->new($_) };

declare 'RepeatedImportIaCError',
    as ArrayRef[ImportIaCError()];

coerce 'RepeatedImportIaCError',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Ingestion::ImportIaCError'->new($_) } @$_ ] };

declare 'MapStringImportIaCError',
    as HashRef[ImportIaCError()];

declare 'Type',
    as (Int | Str);

declare 'ErrorCode',
    as (Int | Str);

declare 'CodeRange',
    as InstanceOf['Google::Cloud::Designcenter::V1::Ingestion::CodeRange'];

coerce 'CodeRange',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Ingestion::CodeRange'->new($_) };

declare 'RepeatedCodeRange',
    as ArrayRef[CodeRange()];

coerce 'RepeatedCodeRange',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Ingestion::CodeRange'->new($_) } @$_ ] };

declare 'MapStringCodeRange',
    as HashRef[CodeRange()];

declare 'CodePosition',
    as InstanceOf['Google::Cloud::Designcenter::V1::Ingestion::CodePosition'];

coerce 'CodePosition',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Ingestion::CodePosition'->new($_) };

declare 'RepeatedCodePosition',
    as ArrayRef[CodePosition()];

coerce 'RepeatedCodePosition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Ingestion::CodePosition'->new($_) } @$_ ] };

declare 'MapStringCodePosition',
    as HashRef[CodePosition()];

1;

__END__

=head1 NAME

Google::Cloud::Designcenter::V1::Ingestion::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
