package Google::Cloud::Dataproc::V1::SessionTemplates::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateSessionTemplateRequest',
    as InstanceOf['Google::Cloud::Dataproc::V1::SessionTemplates::CreateSessionTemplateRequest'];

coerce 'CreateSessionTemplateRequest',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::SessionTemplates::CreateSessionTemplateRequest'->new($_) };

declare 'RepeatedCreateSessionTemplateRequest',
    as ArrayRef[CreateSessionTemplateRequest()];

coerce 'RepeatedCreateSessionTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::SessionTemplates::CreateSessionTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringCreateSessionTemplateRequest',
    as HashRef[CreateSessionTemplateRequest()];

declare 'UpdateSessionTemplateRequest',
    as InstanceOf['Google::Cloud::Dataproc::V1::SessionTemplates::UpdateSessionTemplateRequest'];

coerce 'UpdateSessionTemplateRequest',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::SessionTemplates::UpdateSessionTemplateRequest'->new($_) };

declare 'RepeatedUpdateSessionTemplateRequest',
    as ArrayRef[UpdateSessionTemplateRequest()];

coerce 'RepeatedUpdateSessionTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::SessionTemplates::UpdateSessionTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateSessionTemplateRequest',
    as HashRef[UpdateSessionTemplateRequest()];

declare 'GetSessionTemplateRequest',
    as InstanceOf['Google::Cloud::Dataproc::V1::SessionTemplates::GetSessionTemplateRequest'];

coerce 'GetSessionTemplateRequest',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::SessionTemplates::GetSessionTemplateRequest'->new($_) };

declare 'RepeatedGetSessionTemplateRequest',
    as ArrayRef[GetSessionTemplateRequest()];

coerce 'RepeatedGetSessionTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::SessionTemplates::GetSessionTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringGetSessionTemplateRequest',
    as HashRef[GetSessionTemplateRequest()];

declare 'ListSessionTemplatesRequest',
    as InstanceOf['Google::Cloud::Dataproc::V1::SessionTemplates::ListSessionTemplatesRequest'];

coerce 'ListSessionTemplatesRequest',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::SessionTemplates::ListSessionTemplatesRequest'->new($_) };

declare 'RepeatedListSessionTemplatesRequest',
    as ArrayRef[ListSessionTemplatesRequest()];

coerce 'RepeatedListSessionTemplatesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::SessionTemplates::ListSessionTemplatesRequest'->new($_) } @$_ ] };

declare 'MapStringListSessionTemplatesRequest',
    as HashRef[ListSessionTemplatesRequest()];

declare 'ListSessionTemplatesResponse',
    as InstanceOf['Google::Cloud::Dataproc::V1::SessionTemplates::ListSessionTemplatesResponse'];

coerce 'ListSessionTemplatesResponse',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::SessionTemplates::ListSessionTemplatesResponse'->new($_) };

declare 'RepeatedListSessionTemplatesResponse',
    as ArrayRef[ListSessionTemplatesResponse()];

coerce 'RepeatedListSessionTemplatesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::SessionTemplates::ListSessionTemplatesResponse'->new($_) } @$_ ] };

declare 'MapStringListSessionTemplatesResponse',
    as HashRef[ListSessionTemplatesResponse()];

declare 'DeleteSessionTemplateRequest',
    as InstanceOf['Google::Cloud::Dataproc::V1::SessionTemplates::DeleteSessionTemplateRequest'];

coerce 'DeleteSessionTemplateRequest',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::SessionTemplates::DeleteSessionTemplateRequest'->new($_) };

declare 'RepeatedDeleteSessionTemplateRequest',
    as ArrayRef[DeleteSessionTemplateRequest()];

coerce 'RepeatedDeleteSessionTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::SessionTemplates::DeleteSessionTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteSessionTemplateRequest',
    as HashRef[DeleteSessionTemplateRequest()];

declare 'SessionTemplate',
    as InstanceOf['Google::Cloud::Dataproc::V1::SessionTemplates::SessionTemplate'];

coerce 'SessionTemplate',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::SessionTemplates::SessionTemplate'->new($_) };

declare 'RepeatedSessionTemplate',
    as ArrayRef[SessionTemplate()];

coerce 'RepeatedSessionTemplate',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::SessionTemplates::SessionTemplate'->new($_) } @$_ ] };

declare 'MapStringSessionTemplate',
    as HashRef[SessionTemplate()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Dataproc::V1::SessionTemplates::SessionTemplate::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::SessionTemplates::SessionTemplate::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::SessionTemplates::SessionTemplate::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Dataproc::V1::SessionTemplates::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
