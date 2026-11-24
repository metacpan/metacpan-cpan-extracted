package Google::Cloud::Dialogflow::Cx::V3::Page::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Page',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Page::Page'];

coerce 'Page',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Page::Page'->new($_) };

declare 'RepeatedPage',
    as ArrayRef[Page()];

coerce 'RepeatedPage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Page::Page'->new($_) } @$_ ] };

declare 'MapStringPage',
    as HashRef[Page()];

declare 'Form',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Page::Form'];

coerce 'Form',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Page::Form'->new($_) };

declare 'RepeatedForm',
    as ArrayRef[Form()];

coerce 'RepeatedForm',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Page::Form'->new($_) } @$_ ] };

declare 'MapStringForm',
    as HashRef[Form()];

declare 'Parameter',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Page::Form::Parameter'];

coerce 'Parameter',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Page::Form::Parameter'->new($_) };

declare 'RepeatedParameter',
    as ArrayRef[Parameter()];

coerce 'RepeatedParameter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Page::Form::Parameter'->new($_) } @$_ ] };

declare 'MapStringParameter',
    as HashRef[Parameter()];

declare 'FillBehavior',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Page::Form::Parameter::FillBehavior'];

coerce 'FillBehavior',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Page::Form::Parameter::FillBehavior'->new($_) };

declare 'RepeatedFillBehavior',
    as ArrayRef[FillBehavior()];

coerce 'RepeatedFillBehavior',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Page::Form::Parameter::FillBehavior'->new($_) } @$_ ] };

declare 'MapStringFillBehavior',
    as HashRef[FillBehavior()];

declare 'EventHandler',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Page::EventHandler'];

coerce 'EventHandler',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Page::EventHandler'->new($_) };

declare 'RepeatedEventHandler',
    as ArrayRef[EventHandler()];

coerce 'RepeatedEventHandler',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Page::EventHandler'->new($_) } @$_ ] };

declare 'MapStringEventHandler',
    as HashRef[EventHandler()];

declare 'TransitionRoute',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Page::TransitionRoute'];

coerce 'TransitionRoute',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Page::TransitionRoute'->new($_) };

declare 'RepeatedTransitionRoute',
    as ArrayRef[TransitionRoute()];

coerce 'RepeatedTransitionRoute',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Page::TransitionRoute'->new($_) } @$_ ] };

declare 'MapStringTransitionRoute',
    as HashRef[TransitionRoute()];

declare 'ListPagesRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Page::ListPagesRequest'];

coerce 'ListPagesRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Page::ListPagesRequest'->new($_) };

declare 'RepeatedListPagesRequest',
    as ArrayRef[ListPagesRequest()];

coerce 'RepeatedListPagesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Page::ListPagesRequest'->new($_) } @$_ ] };

declare 'MapStringListPagesRequest',
    as HashRef[ListPagesRequest()];

declare 'ListPagesResponse',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Page::ListPagesResponse'];

coerce 'ListPagesResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Page::ListPagesResponse'->new($_) };

declare 'RepeatedListPagesResponse',
    as ArrayRef[ListPagesResponse()];

coerce 'RepeatedListPagesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Page::ListPagesResponse'->new($_) } @$_ ] };

declare 'MapStringListPagesResponse',
    as HashRef[ListPagesResponse()];

declare 'GetPageRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Page::GetPageRequest'];

coerce 'GetPageRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Page::GetPageRequest'->new($_) };

declare 'RepeatedGetPageRequest',
    as ArrayRef[GetPageRequest()];

coerce 'RepeatedGetPageRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Page::GetPageRequest'->new($_) } @$_ ] };

declare 'MapStringGetPageRequest',
    as HashRef[GetPageRequest()];

declare 'CreatePageRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Page::CreatePageRequest'];

coerce 'CreatePageRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Page::CreatePageRequest'->new($_) };

declare 'RepeatedCreatePageRequest',
    as ArrayRef[CreatePageRequest()];

coerce 'RepeatedCreatePageRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Page::CreatePageRequest'->new($_) } @$_ ] };

declare 'MapStringCreatePageRequest',
    as HashRef[CreatePageRequest()];

declare 'UpdatePageRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Page::UpdatePageRequest'];

coerce 'UpdatePageRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Page::UpdatePageRequest'->new($_) };

declare 'RepeatedUpdatePageRequest',
    as ArrayRef[UpdatePageRequest()];

coerce 'RepeatedUpdatePageRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Page::UpdatePageRequest'->new($_) } @$_ ] };

declare 'MapStringUpdatePageRequest',
    as HashRef[UpdatePageRequest()];

declare 'DeletePageRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Page::DeletePageRequest'];

coerce 'DeletePageRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Page::DeletePageRequest'->new($_) };

declare 'RepeatedDeletePageRequest',
    as ArrayRef[DeletePageRequest()];

coerce 'RepeatedDeletePageRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Page::DeletePageRequest'->new($_) } @$_ ] };

declare 'MapStringDeletePageRequest',
    as HashRef[DeletePageRequest()];

declare 'KnowledgeConnectorSettings',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Page::KnowledgeConnectorSettings'];

coerce 'KnowledgeConnectorSettings',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Page::KnowledgeConnectorSettings'->new($_) };

declare 'RepeatedKnowledgeConnectorSettings',
    as ArrayRef[KnowledgeConnectorSettings()];

coerce 'RepeatedKnowledgeConnectorSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Page::KnowledgeConnectorSettings'->new($_) } @$_ ] };

declare 'MapStringKnowledgeConnectorSettings',
    as HashRef[KnowledgeConnectorSettings()];

1;

__END__

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3::Page::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
