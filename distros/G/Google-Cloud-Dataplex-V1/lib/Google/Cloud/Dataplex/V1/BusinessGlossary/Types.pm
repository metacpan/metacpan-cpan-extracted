package Google::Cloud::Dataplex::V1::BusinessGlossary::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Glossary',
    as InstanceOf['Google::Cloud::Dataplex::V1::BusinessGlossary::Glossary'];

coerce 'Glossary',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::BusinessGlossary::Glossary'->new($_) };

declare 'RepeatedGlossary',
    as ArrayRef[Glossary()];

coerce 'RepeatedGlossary',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::BusinessGlossary::Glossary'->new($_) } @$_ ] };

declare 'MapStringGlossary',
    as HashRef[Glossary()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Dataplex::V1::BusinessGlossary::Glossary::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::BusinessGlossary::Glossary::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::BusinessGlossary::Glossary::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'GlossaryCategory',
    as InstanceOf['Google::Cloud::Dataplex::V1::BusinessGlossary::GlossaryCategory'];

coerce 'GlossaryCategory',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::BusinessGlossary::GlossaryCategory'->new($_) };

declare 'RepeatedGlossaryCategory',
    as ArrayRef[GlossaryCategory()];

coerce 'RepeatedGlossaryCategory',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::BusinessGlossary::GlossaryCategory'->new($_) } @$_ ] };

declare 'MapStringGlossaryCategory',
    as HashRef[GlossaryCategory()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Dataplex::V1::BusinessGlossary::GlossaryCategory::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::BusinessGlossary::GlossaryCategory::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::BusinessGlossary::GlossaryCategory::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'GlossaryTerm',
    as InstanceOf['Google::Cloud::Dataplex::V1::BusinessGlossary::GlossaryTerm'];

coerce 'GlossaryTerm',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::BusinessGlossary::GlossaryTerm'->new($_) };

declare 'RepeatedGlossaryTerm',
    as ArrayRef[GlossaryTerm()];

coerce 'RepeatedGlossaryTerm',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::BusinessGlossary::GlossaryTerm'->new($_) } @$_ ] };

declare 'MapStringGlossaryTerm',
    as HashRef[GlossaryTerm()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Dataplex::V1::BusinessGlossary::GlossaryTerm::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::BusinessGlossary::GlossaryTerm::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::BusinessGlossary::GlossaryTerm::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'CreateGlossaryRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::BusinessGlossary::CreateGlossaryRequest'];

coerce 'CreateGlossaryRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::BusinessGlossary::CreateGlossaryRequest'->new($_) };

declare 'RepeatedCreateGlossaryRequest',
    as ArrayRef[CreateGlossaryRequest()];

coerce 'RepeatedCreateGlossaryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::BusinessGlossary::CreateGlossaryRequest'->new($_) } @$_ ] };

declare 'MapStringCreateGlossaryRequest',
    as HashRef[CreateGlossaryRequest()];

declare 'UpdateGlossaryRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::BusinessGlossary::UpdateGlossaryRequest'];

coerce 'UpdateGlossaryRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::BusinessGlossary::UpdateGlossaryRequest'->new($_) };

declare 'RepeatedUpdateGlossaryRequest',
    as ArrayRef[UpdateGlossaryRequest()];

coerce 'RepeatedUpdateGlossaryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::BusinessGlossary::UpdateGlossaryRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateGlossaryRequest',
    as HashRef[UpdateGlossaryRequest()];

declare 'DeleteGlossaryRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::BusinessGlossary::DeleteGlossaryRequest'];

coerce 'DeleteGlossaryRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::BusinessGlossary::DeleteGlossaryRequest'->new($_) };

declare 'RepeatedDeleteGlossaryRequest',
    as ArrayRef[DeleteGlossaryRequest()];

coerce 'RepeatedDeleteGlossaryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::BusinessGlossary::DeleteGlossaryRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteGlossaryRequest',
    as HashRef[DeleteGlossaryRequest()];

declare 'GetGlossaryRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::BusinessGlossary::GetGlossaryRequest'];

coerce 'GetGlossaryRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::BusinessGlossary::GetGlossaryRequest'->new($_) };

declare 'RepeatedGetGlossaryRequest',
    as ArrayRef[GetGlossaryRequest()];

coerce 'RepeatedGetGlossaryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::BusinessGlossary::GetGlossaryRequest'->new($_) } @$_ ] };

declare 'MapStringGetGlossaryRequest',
    as HashRef[GetGlossaryRequest()];

declare 'ListGlossariesRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::BusinessGlossary::ListGlossariesRequest'];

coerce 'ListGlossariesRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::BusinessGlossary::ListGlossariesRequest'->new($_) };

declare 'RepeatedListGlossariesRequest',
    as ArrayRef[ListGlossariesRequest()];

coerce 'RepeatedListGlossariesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::BusinessGlossary::ListGlossariesRequest'->new($_) } @$_ ] };

declare 'MapStringListGlossariesRequest',
    as HashRef[ListGlossariesRequest()];

declare 'ListGlossariesResponse',
    as InstanceOf['Google::Cloud::Dataplex::V1::BusinessGlossary::ListGlossariesResponse'];

coerce 'ListGlossariesResponse',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::BusinessGlossary::ListGlossariesResponse'->new($_) };

declare 'RepeatedListGlossariesResponse',
    as ArrayRef[ListGlossariesResponse()];

coerce 'RepeatedListGlossariesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::BusinessGlossary::ListGlossariesResponse'->new($_) } @$_ ] };

declare 'MapStringListGlossariesResponse',
    as HashRef[ListGlossariesResponse()];

declare 'CreateGlossaryCategoryRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::BusinessGlossary::CreateGlossaryCategoryRequest'];

coerce 'CreateGlossaryCategoryRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::BusinessGlossary::CreateGlossaryCategoryRequest'->new($_) };

declare 'RepeatedCreateGlossaryCategoryRequest',
    as ArrayRef[CreateGlossaryCategoryRequest()];

coerce 'RepeatedCreateGlossaryCategoryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::BusinessGlossary::CreateGlossaryCategoryRequest'->new($_) } @$_ ] };

declare 'MapStringCreateGlossaryCategoryRequest',
    as HashRef[CreateGlossaryCategoryRequest()];

declare 'UpdateGlossaryCategoryRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::BusinessGlossary::UpdateGlossaryCategoryRequest'];

coerce 'UpdateGlossaryCategoryRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::BusinessGlossary::UpdateGlossaryCategoryRequest'->new($_) };

declare 'RepeatedUpdateGlossaryCategoryRequest',
    as ArrayRef[UpdateGlossaryCategoryRequest()];

coerce 'RepeatedUpdateGlossaryCategoryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::BusinessGlossary::UpdateGlossaryCategoryRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateGlossaryCategoryRequest',
    as HashRef[UpdateGlossaryCategoryRequest()];

declare 'DeleteGlossaryCategoryRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::BusinessGlossary::DeleteGlossaryCategoryRequest'];

coerce 'DeleteGlossaryCategoryRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::BusinessGlossary::DeleteGlossaryCategoryRequest'->new($_) };

declare 'RepeatedDeleteGlossaryCategoryRequest',
    as ArrayRef[DeleteGlossaryCategoryRequest()];

coerce 'RepeatedDeleteGlossaryCategoryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::BusinessGlossary::DeleteGlossaryCategoryRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteGlossaryCategoryRequest',
    as HashRef[DeleteGlossaryCategoryRequest()];

declare 'GetGlossaryCategoryRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::BusinessGlossary::GetGlossaryCategoryRequest'];

coerce 'GetGlossaryCategoryRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::BusinessGlossary::GetGlossaryCategoryRequest'->new($_) };

declare 'RepeatedGetGlossaryCategoryRequest',
    as ArrayRef[GetGlossaryCategoryRequest()];

coerce 'RepeatedGetGlossaryCategoryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::BusinessGlossary::GetGlossaryCategoryRequest'->new($_) } @$_ ] };

declare 'MapStringGetGlossaryCategoryRequest',
    as HashRef[GetGlossaryCategoryRequest()];

declare 'ListGlossaryCategoriesRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::BusinessGlossary::ListGlossaryCategoriesRequest'];

coerce 'ListGlossaryCategoriesRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::BusinessGlossary::ListGlossaryCategoriesRequest'->new($_) };

declare 'RepeatedListGlossaryCategoriesRequest',
    as ArrayRef[ListGlossaryCategoriesRequest()];

coerce 'RepeatedListGlossaryCategoriesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::BusinessGlossary::ListGlossaryCategoriesRequest'->new($_) } @$_ ] };

declare 'MapStringListGlossaryCategoriesRequest',
    as HashRef[ListGlossaryCategoriesRequest()];

declare 'ListGlossaryCategoriesResponse',
    as InstanceOf['Google::Cloud::Dataplex::V1::BusinessGlossary::ListGlossaryCategoriesResponse'];

coerce 'ListGlossaryCategoriesResponse',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::BusinessGlossary::ListGlossaryCategoriesResponse'->new($_) };

declare 'RepeatedListGlossaryCategoriesResponse',
    as ArrayRef[ListGlossaryCategoriesResponse()];

coerce 'RepeatedListGlossaryCategoriesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::BusinessGlossary::ListGlossaryCategoriesResponse'->new($_) } @$_ ] };

declare 'MapStringListGlossaryCategoriesResponse',
    as HashRef[ListGlossaryCategoriesResponse()];

declare 'CreateGlossaryTermRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::BusinessGlossary::CreateGlossaryTermRequest'];

coerce 'CreateGlossaryTermRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::BusinessGlossary::CreateGlossaryTermRequest'->new($_) };

declare 'RepeatedCreateGlossaryTermRequest',
    as ArrayRef[CreateGlossaryTermRequest()];

coerce 'RepeatedCreateGlossaryTermRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::BusinessGlossary::CreateGlossaryTermRequest'->new($_) } @$_ ] };

declare 'MapStringCreateGlossaryTermRequest',
    as HashRef[CreateGlossaryTermRequest()];

declare 'UpdateGlossaryTermRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::BusinessGlossary::UpdateGlossaryTermRequest'];

coerce 'UpdateGlossaryTermRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::BusinessGlossary::UpdateGlossaryTermRequest'->new($_) };

declare 'RepeatedUpdateGlossaryTermRequest',
    as ArrayRef[UpdateGlossaryTermRequest()];

coerce 'RepeatedUpdateGlossaryTermRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::BusinessGlossary::UpdateGlossaryTermRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateGlossaryTermRequest',
    as HashRef[UpdateGlossaryTermRequest()];

declare 'DeleteGlossaryTermRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::BusinessGlossary::DeleteGlossaryTermRequest'];

coerce 'DeleteGlossaryTermRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::BusinessGlossary::DeleteGlossaryTermRequest'->new($_) };

declare 'RepeatedDeleteGlossaryTermRequest',
    as ArrayRef[DeleteGlossaryTermRequest()];

coerce 'RepeatedDeleteGlossaryTermRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::BusinessGlossary::DeleteGlossaryTermRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteGlossaryTermRequest',
    as HashRef[DeleteGlossaryTermRequest()];

declare 'GetGlossaryTermRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::BusinessGlossary::GetGlossaryTermRequest'];

coerce 'GetGlossaryTermRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::BusinessGlossary::GetGlossaryTermRequest'->new($_) };

declare 'RepeatedGetGlossaryTermRequest',
    as ArrayRef[GetGlossaryTermRequest()];

coerce 'RepeatedGetGlossaryTermRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::BusinessGlossary::GetGlossaryTermRequest'->new($_) } @$_ ] };

declare 'MapStringGetGlossaryTermRequest',
    as HashRef[GetGlossaryTermRequest()];

declare 'ListGlossaryTermsRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::BusinessGlossary::ListGlossaryTermsRequest'];

coerce 'ListGlossaryTermsRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::BusinessGlossary::ListGlossaryTermsRequest'->new($_) };

declare 'RepeatedListGlossaryTermsRequest',
    as ArrayRef[ListGlossaryTermsRequest()];

coerce 'RepeatedListGlossaryTermsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::BusinessGlossary::ListGlossaryTermsRequest'->new($_) } @$_ ] };

declare 'MapStringListGlossaryTermsRequest',
    as HashRef[ListGlossaryTermsRequest()];

declare 'ListGlossaryTermsResponse',
    as InstanceOf['Google::Cloud::Dataplex::V1::BusinessGlossary::ListGlossaryTermsResponse'];

coerce 'ListGlossaryTermsResponse',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::BusinessGlossary::ListGlossaryTermsResponse'->new($_) };

declare 'RepeatedListGlossaryTermsResponse',
    as ArrayRef[ListGlossaryTermsResponse()];

coerce 'RepeatedListGlossaryTermsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::BusinessGlossary::ListGlossaryTermsResponse'->new($_) } @$_ ] };

declare 'MapStringListGlossaryTermsResponse',
    as HashRef[ListGlossaryTermsResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Dataplex::V1::BusinessGlossary::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
