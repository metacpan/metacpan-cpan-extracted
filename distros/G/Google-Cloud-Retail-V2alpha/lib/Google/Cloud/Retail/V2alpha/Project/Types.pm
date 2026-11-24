package Google::Cloud::Retail::V2alpha::Project::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'LoggingConfig',
    as InstanceOf['Google::Cloud::Retail::V2alpha::Project::LoggingConfig'];

coerce 'LoggingConfig',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::Project::LoggingConfig'->new($_) };

declare 'RepeatedLoggingConfig',
    as ArrayRef[LoggingConfig()];

coerce 'RepeatedLoggingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::Project::LoggingConfig'->new($_) } @$_ ] };

declare 'MapStringLoggingConfig',
    as HashRef[LoggingConfig()];

declare 'LoggingLevel',
    as (Int | Str);

declare 'LogGenerationRule',
    as InstanceOf['Google::Cloud::Retail::V2alpha::Project::LoggingConfig::LogGenerationRule'];

coerce 'LogGenerationRule',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::Project::LoggingConfig::LogGenerationRule'->new($_) };

declare 'RepeatedLogGenerationRule',
    as ArrayRef[LogGenerationRule()];

coerce 'RepeatedLogGenerationRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::Project::LoggingConfig::LogGenerationRule'->new($_) } @$_ ] };

declare 'MapStringLogGenerationRule',
    as HashRef[LogGenerationRule()];

declare 'ServiceLogGenerationRule',
    as InstanceOf['Google::Cloud::Retail::V2alpha::Project::LoggingConfig::ServiceLogGenerationRule'];

coerce 'ServiceLogGenerationRule',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::Project::LoggingConfig::ServiceLogGenerationRule'->new($_) };

declare 'RepeatedServiceLogGenerationRule',
    as ArrayRef[ServiceLogGenerationRule()];

coerce 'RepeatedServiceLogGenerationRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::Project::LoggingConfig::ServiceLogGenerationRule'->new($_) } @$_ ] };

declare 'MapStringServiceLogGenerationRule',
    as HashRef[ServiceLogGenerationRule()];

declare 'Project',
    as InstanceOf['Google::Cloud::Retail::V2alpha::Project::Project'];

coerce 'Project',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::Project::Project'->new($_) };

declare 'RepeatedProject',
    as ArrayRef[Project()];

coerce 'RepeatedProject',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::Project::Project'->new($_) } @$_ ] };

declare 'MapStringProject',
    as HashRef[Project()];

declare 'AlertConfig',
    as InstanceOf['Google::Cloud::Retail::V2alpha::Project::AlertConfig'];

coerce 'AlertConfig',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::Project::AlertConfig'->new($_) };

declare 'RepeatedAlertConfig',
    as ArrayRef[AlertConfig()];

coerce 'RepeatedAlertConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::Project::AlertConfig'->new($_) } @$_ ] };

declare 'MapStringAlertConfig',
    as HashRef[AlertConfig()];

declare 'AlertPolicy',
    as InstanceOf['Google::Cloud::Retail::V2alpha::Project::AlertConfig::AlertPolicy'];

coerce 'AlertPolicy',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::Project::AlertConfig::AlertPolicy'->new($_) };

declare 'RepeatedAlertPolicy',
    as ArrayRef[AlertPolicy()];

coerce 'RepeatedAlertPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::Project::AlertConfig::AlertPolicy'->new($_) } @$_ ] };

declare 'MapStringAlertPolicy',
    as HashRef[AlertPolicy()];

declare 'EnrollStatus',
    as (Int | Str);

declare 'Recipient',
    as InstanceOf['Google::Cloud::Retail::V2alpha::Project::AlertConfig::AlertPolicy::Recipient'];

coerce 'Recipient',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::Project::AlertConfig::AlertPolicy::Recipient'->new($_) };

declare 'RepeatedRecipient',
    as ArrayRef[Recipient()];

coerce 'RepeatedRecipient',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::Project::AlertConfig::AlertPolicy::Recipient'->new($_) } @$_ ] };

declare 'MapStringRecipient',
    as HashRef[Recipient()];

1;

__END__

=head1 NAME

Google::Cloud::Retail::V2alpha::Project::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
