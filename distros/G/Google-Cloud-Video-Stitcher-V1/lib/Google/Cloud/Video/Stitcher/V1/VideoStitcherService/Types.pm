package Google::Cloud::Video::Stitcher::V1::VideoStitcherService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateCdnKeyRequest',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::VideoStitcherService::CreateCdnKeyRequest'];

coerce 'CreateCdnKeyRequest',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::CreateCdnKeyRequest'->new($_) };

declare 'RepeatedCreateCdnKeyRequest',
    as ArrayRef[CreateCdnKeyRequest()];

coerce 'RepeatedCreateCdnKeyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::CreateCdnKeyRequest'->new($_) } @$_ ] };

declare 'MapStringCreateCdnKeyRequest',
    as HashRef[CreateCdnKeyRequest()];

declare 'ListCdnKeysRequest',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::VideoStitcherService::ListCdnKeysRequest'];

coerce 'ListCdnKeysRequest',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::ListCdnKeysRequest'->new($_) };

declare 'RepeatedListCdnKeysRequest',
    as ArrayRef[ListCdnKeysRequest()];

coerce 'RepeatedListCdnKeysRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::ListCdnKeysRequest'->new($_) } @$_ ] };

declare 'MapStringListCdnKeysRequest',
    as HashRef[ListCdnKeysRequest()];

declare 'ListCdnKeysResponse',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::VideoStitcherService::ListCdnKeysResponse'];

coerce 'ListCdnKeysResponse',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::ListCdnKeysResponse'->new($_) };

declare 'RepeatedListCdnKeysResponse',
    as ArrayRef[ListCdnKeysResponse()];

coerce 'RepeatedListCdnKeysResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::ListCdnKeysResponse'->new($_) } @$_ ] };

declare 'MapStringListCdnKeysResponse',
    as HashRef[ListCdnKeysResponse()];

declare 'GetCdnKeyRequest',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::VideoStitcherService::GetCdnKeyRequest'];

coerce 'GetCdnKeyRequest',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::GetCdnKeyRequest'->new($_) };

declare 'RepeatedGetCdnKeyRequest',
    as ArrayRef[GetCdnKeyRequest()];

coerce 'RepeatedGetCdnKeyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::GetCdnKeyRequest'->new($_) } @$_ ] };

declare 'MapStringGetCdnKeyRequest',
    as HashRef[GetCdnKeyRequest()];

declare 'DeleteCdnKeyRequest',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::VideoStitcherService::DeleteCdnKeyRequest'];

coerce 'DeleteCdnKeyRequest',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::DeleteCdnKeyRequest'->new($_) };

declare 'RepeatedDeleteCdnKeyRequest',
    as ArrayRef[DeleteCdnKeyRequest()];

coerce 'RepeatedDeleteCdnKeyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::DeleteCdnKeyRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteCdnKeyRequest',
    as HashRef[DeleteCdnKeyRequest()];

declare 'UpdateCdnKeyRequest',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::VideoStitcherService::UpdateCdnKeyRequest'];

coerce 'UpdateCdnKeyRequest',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::UpdateCdnKeyRequest'->new($_) };

declare 'RepeatedUpdateCdnKeyRequest',
    as ArrayRef[UpdateCdnKeyRequest()];

coerce 'RepeatedUpdateCdnKeyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::UpdateCdnKeyRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateCdnKeyRequest',
    as HashRef[UpdateCdnKeyRequest()];

declare 'CreateVodSessionRequest',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::VideoStitcherService::CreateVodSessionRequest'];

coerce 'CreateVodSessionRequest',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::CreateVodSessionRequest'->new($_) };

declare 'RepeatedCreateVodSessionRequest',
    as ArrayRef[CreateVodSessionRequest()];

coerce 'RepeatedCreateVodSessionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::CreateVodSessionRequest'->new($_) } @$_ ] };

declare 'MapStringCreateVodSessionRequest',
    as HashRef[CreateVodSessionRequest()];

declare 'GetVodSessionRequest',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::VideoStitcherService::GetVodSessionRequest'];

coerce 'GetVodSessionRequest',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::GetVodSessionRequest'->new($_) };

declare 'RepeatedGetVodSessionRequest',
    as ArrayRef[GetVodSessionRequest()];

coerce 'RepeatedGetVodSessionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::GetVodSessionRequest'->new($_) } @$_ ] };

declare 'MapStringGetVodSessionRequest',
    as HashRef[GetVodSessionRequest()];

declare 'ListVodStitchDetailsRequest',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::VideoStitcherService::ListVodStitchDetailsRequest'];

coerce 'ListVodStitchDetailsRequest',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::ListVodStitchDetailsRequest'->new($_) };

declare 'RepeatedListVodStitchDetailsRequest',
    as ArrayRef[ListVodStitchDetailsRequest()];

coerce 'RepeatedListVodStitchDetailsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::ListVodStitchDetailsRequest'->new($_) } @$_ ] };

declare 'MapStringListVodStitchDetailsRequest',
    as HashRef[ListVodStitchDetailsRequest()];

declare 'ListVodStitchDetailsResponse',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::VideoStitcherService::ListVodStitchDetailsResponse'];

coerce 'ListVodStitchDetailsResponse',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::ListVodStitchDetailsResponse'->new($_) };

declare 'RepeatedListVodStitchDetailsResponse',
    as ArrayRef[ListVodStitchDetailsResponse()];

coerce 'RepeatedListVodStitchDetailsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::ListVodStitchDetailsResponse'->new($_) } @$_ ] };

declare 'MapStringListVodStitchDetailsResponse',
    as HashRef[ListVodStitchDetailsResponse()];

declare 'GetVodStitchDetailRequest',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::VideoStitcherService::GetVodStitchDetailRequest'];

coerce 'GetVodStitchDetailRequest',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::GetVodStitchDetailRequest'->new($_) };

declare 'RepeatedGetVodStitchDetailRequest',
    as ArrayRef[GetVodStitchDetailRequest()];

coerce 'RepeatedGetVodStitchDetailRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::GetVodStitchDetailRequest'->new($_) } @$_ ] };

declare 'MapStringGetVodStitchDetailRequest',
    as HashRef[GetVodStitchDetailRequest()];

declare 'ListVodAdTagDetailsRequest',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::VideoStitcherService::ListVodAdTagDetailsRequest'];

coerce 'ListVodAdTagDetailsRequest',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::ListVodAdTagDetailsRequest'->new($_) };

declare 'RepeatedListVodAdTagDetailsRequest',
    as ArrayRef[ListVodAdTagDetailsRequest()];

coerce 'RepeatedListVodAdTagDetailsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::ListVodAdTagDetailsRequest'->new($_) } @$_ ] };

declare 'MapStringListVodAdTagDetailsRequest',
    as HashRef[ListVodAdTagDetailsRequest()];

declare 'ListVodAdTagDetailsResponse',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::VideoStitcherService::ListVodAdTagDetailsResponse'];

coerce 'ListVodAdTagDetailsResponse',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::ListVodAdTagDetailsResponse'->new($_) };

declare 'RepeatedListVodAdTagDetailsResponse',
    as ArrayRef[ListVodAdTagDetailsResponse()];

coerce 'RepeatedListVodAdTagDetailsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::ListVodAdTagDetailsResponse'->new($_) } @$_ ] };

declare 'MapStringListVodAdTagDetailsResponse',
    as HashRef[ListVodAdTagDetailsResponse()];

declare 'GetVodAdTagDetailRequest',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::VideoStitcherService::GetVodAdTagDetailRequest'];

coerce 'GetVodAdTagDetailRequest',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::GetVodAdTagDetailRequest'->new($_) };

declare 'RepeatedGetVodAdTagDetailRequest',
    as ArrayRef[GetVodAdTagDetailRequest()];

coerce 'RepeatedGetVodAdTagDetailRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::GetVodAdTagDetailRequest'->new($_) } @$_ ] };

declare 'MapStringGetVodAdTagDetailRequest',
    as HashRef[GetVodAdTagDetailRequest()];

declare 'ListLiveAdTagDetailsRequest',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::VideoStitcherService::ListLiveAdTagDetailsRequest'];

coerce 'ListLiveAdTagDetailsRequest',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::ListLiveAdTagDetailsRequest'->new($_) };

declare 'RepeatedListLiveAdTagDetailsRequest',
    as ArrayRef[ListLiveAdTagDetailsRequest()];

coerce 'RepeatedListLiveAdTagDetailsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::ListLiveAdTagDetailsRequest'->new($_) } @$_ ] };

declare 'MapStringListLiveAdTagDetailsRequest',
    as HashRef[ListLiveAdTagDetailsRequest()];

declare 'ListLiveAdTagDetailsResponse',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::VideoStitcherService::ListLiveAdTagDetailsResponse'];

coerce 'ListLiveAdTagDetailsResponse',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::ListLiveAdTagDetailsResponse'->new($_) };

declare 'RepeatedListLiveAdTagDetailsResponse',
    as ArrayRef[ListLiveAdTagDetailsResponse()];

coerce 'RepeatedListLiveAdTagDetailsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::ListLiveAdTagDetailsResponse'->new($_) } @$_ ] };

declare 'MapStringListLiveAdTagDetailsResponse',
    as HashRef[ListLiveAdTagDetailsResponse()];

declare 'GetLiveAdTagDetailRequest',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::VideoStitcherService::GetLiveAdTagDetailRequest'];

coerce 'GetLiveAdTagDetailRequest',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::GetLiveAdTagDetailRequest'->new($_) };

declare 'RepeatedGetLiveAdTagDetailRequest',
    as ArrayRef[GetLiveAdTagDetailRequest()];

coerce 'RepeatedGetLiveAdTagDetailRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::GetLiveAdTagDetailRequest'->new($_) } @$_ ] };

declare 'MapStringGetLiveAdTagDetailRequest',
    as HashRef[GetLiveAdTagDetailRequest()];

declare 'CreateSlateRequest',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::VideoStitcherService::CreateSlateRequest'];

coerce 'CreateSlateRequest',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::CreateSlateRequest'->new($_) };

declare 'RepeatedCreateSlateRequest',
    as ArrayRef[CreateSlateRequest()];

coerce 'RepeatedCreateSlateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::CreateSlateRequest'->new($_) } @$_ ] };

declare 'MapStringCreateSlateRequest',
    as HashRef[CreateSlateRequest()];

declare 'GetSlateRequest',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::VideoStitcherService::GetSlateRequest'];

coerce 'GetSlateRequest',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::GetSlateRequest'->new($_) };

declare 'RepeatedGetSlateRequest',
    as ArrayRef[GetSlateRequest()];

coerce 'RepeatedGetSlateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::GetSlateRequest'->new($_) } @$_ ] };

declare 'MapStringGetSlateRequest',
    as HashRef[GetSlateRequest()];

declare 'ListSlatesRequest',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::VideoStitcherService::ListSlatesRequest'];

coerce 'ListSlatesRequest',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::ListSlatesRequest'->new($_) };

declare 'RepeatedListSlatesRequest',
    as ArrayRef[ListSlatesRequest()];

coerce 'RepeatedListSlatesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::ListSlatesRequest'->new($_) } @$_ ] };

declare 'MapStringListSlatesRequest',
    as HashRef[ListSlatesRequest()];

declare 'ListSlatesResponse',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::VideoStitcherService::ListSlatesResponse'];

coerce 'ListSlatesResponse',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::ListSlatesResponse'->new($_) };

declare 'RepeatedListSlatesResponse',
    as ArrayRef[ListSlatesResponse()];

coerce 'RepeatedListSlatesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::ListSlatesResponse'->new($_) } @$_ ] };

declare 'MapStringListSlatesResponse',
    as HashRef[ListSlatesResponse()];

declare 'UpdateSlateRequest',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::VideoStitcherService::UpdateSlateRequest'];

coerce 'UpdateSlateRequest',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::UpdateSlateRequest'->new($_) };

declare 'RepeatedUpdateSlateRequest',
    as ArrayRef[UpdateSlateRequest()];

coerce 'RepeatedUpdateSlateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::UpdateSlateRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateSlateRequest',
    as HashRef[UpdateSlateRequest()];

declare 'DeleteSlateRequest',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::VideoStitcherService::DeleteSlateRequest'];

coerce 'DeleteSlateRequest',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::DeleteSlateRequest'->new($_) };

declare 'RepeatedDeleteSlateRequest',
    as ArrayRef[DeleteSlateRequest()];

coerce 'RepeatedDeleteSlateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::DeleteSlateRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteSlateRequest',
    as HashRef[DeleteSlateRequest()];

declare 'CreateLiveSessionRequest',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::VideoStitcherService::CreateLiveSessionRequest'];

coerce 'CreateLiveSessionRequest',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::CreateLiveSessionRequest'->new($_) };

declare 'RepeatedCreateLiveSessionRequest',
    as ArrayRef[CreateLiveSessionRequest()];

coerce 'RepeatedCreateLiveSessionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::CreateLiveSessionRequest'->new($_) } @$_ ] };

declare 'MapStringCreateLiveSessionRequest',
    as HashRef[CreateLiveSessionRequest()];

declare 'GetLiveSessionRequest',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::VideoStitcherService::GetLiveSessionRequest'];

coerce 'GetLiveSessionRequest',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::GetLiveSessionRequest'->new($_) };

declare 'RepeatedGetLiveSessionRequest',
    as ArrayRef[GetLiveSessionRequest()];

coerce 'RepeatedGetLiveSessionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::GetLiveSessionRequest'->new($_) } @$_ ] };

declare 'MapStringGetLiveSessionRequest',
    as HashRef[GetLiveSessionRequest()];

declare 'CreateLiveConfigRequest',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::VideoStitcherService::CreateLiveConfigRequest'];

coerce 'CreateLiveConfigRequest',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::CreateLiveConfigRequest'->new($_) };

declare 'RepeatedCreateLiveConfigRequest',
    as ArrayRef[CreateLiveConfigRequest()];

coerce 'RepeatedCreateLiveConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::CreateLiveConfigRequest'->new($_) } @$_ ] };

declare 'MapStringCreateLiveConfigRequest',
    as HashRef[CreateLiveConfigRequest()];

declare 'ListLiveConfigsRequest',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::VideoStitcherService::ListLiveConfigsRequest'];

coerce 'ListLiveConfigsRequest',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::ListLiveConfigsRequest'->new($_) };

declare 'RepeatedListLiveConfigsRequest',
    as ArrayRef[ListLiveConfigsRequest()];

coerce 'RepeatedListLiveConfigsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::ListLiveConfigsRequest'->new($_) } @$_ ] };

declare 'MapStringListLiveConfigsRequest',
    as HashRef[ListLiveConfigsRequest()];

declare 'ListLiveConfigsResponse',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::VideoStitcherService::ListLiveConfigsResponse'];

coerce 'ListLiveConfigsResponse',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::ListLiveConfigsResponse'->new($_) };

declare 'RepeatedListLiveConfigsResponse',
    as ArrayRef[ListLiveConfigsResponse()];

coerce 'RepeatedListLiveConfigsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::ListLiveConfigsResponse'->new($_) } @$_ ] };

declare 'MapStringListLiveConfigsResponse',
    as HashRef[ListLiveConfigsResponse()];

declare 'GetLiveConfigRequest',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::VideoStitcherService::GetLiveConfigRequest'];

coerce 'GetLiveConfigRequest',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::GetLiveConfigRequest'->new($_) };

declare 'RepeatedGetLiveConfigRequest',
    as ArrayRef[GetLiveConfigRequest()];

coerce 'RepeatedGetLiveConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::GetLiveConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetLiveConfigRequest',
    as HashRef[GetLiveConfigRequest()];

declare 'DeleteLiveConfigRequest',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::VideoStitcherService::DeleteLiveConfigRequest'];

coerce 'DeleteLiveConfigRequest',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::DeleteLiveConfigRequest'->new($_) };

declare 'RepeatedDeleteLiveConfigRequest',
    as ArrayRef[DeleteLiveConfigRequest()];

coerce 'RepeatedDeleteLiveConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::DeleteLiveConfigRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteLiveConfigRequest',
    as HashRef[DeleteLiveConfigRequest()];

declare 'UpdateLiveConfigRequest',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::VideoStitcherService::UpdateLiveConfigRequest'];

coerce 'UpdateLiveConfigRequest',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::UpdateLiveConfigRequest'->new($_) };

declare 'RepeatedUpdateLiveConfigRequest',
    as ArrayRef[UpdateLiveConfigRequest()];

coerce 'RepeatedUpdateLiveConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::UpdateLiveConfigRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateLiveConfigRequest',
    as HashRef[UpdateLiveConfigRequest()];

declare 'CreateVodConfigRequest',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::VideoStitcherService::CreateVodConfigRequest'];

coerce 'CreateVodConfigRequest',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::CreateVodConfigRequest'->new($_) };

declare 'RepeatedCreateVodConfigRequest',
    as ArrayRef[CreateVodConfigRequest()];

coerce 'RepeatedCreateVodConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::CreateVodConfigRequest'->new($_) } @$_ ] };

declare 'MapStringCreateVodConfigRequest',
    as HashRef[CreateVodConfigRequest()];

declare 'ListVodConfigsRequest',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::VideoStitcherService::ListVodConfigsRequest'];

coerce 'ListVodConfigsRequest',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::ListVodConfigsRequest'->new($_) };

declare 'RepeatedListVodConfigsRequest',
    as ArrayRef[ListVodConfigsRequest()];

coerce 'RepeatedListVodConfigsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::ListVodConfigsRequest'->new($_) } @$_ ] };

declare 'MapStringListVodConfigsRequest',
    as HashRef[ListVodConfigsRequest()];

declare 'ListVodConfigsResponse',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::VideoStitcherService::ListVodConfigsResponse'];

coerce 'ListVodConfigsResponse',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::ListVodConfigsResponse'->new($_) };

declare 'RepeatedListVodConfigsResponse',
    as ArrayRef[ListVodConfigsResponse()];

coerce 'RepeatedListVodConfigsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::ListVodConfigsResponse'->new($_) } @$_ ] };

declare 'MapStringListVodConfigsResponse',
    as HashRef[ListVodConfigsResponse()];

declare 'GetVodConfigRequest',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::VideoStitcherService::GetVodConfigRequest'];

coerce 'GetVodConfigRequest',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::GetVodConfigRequest'->new($_) };

declare 'RepeatedGetVodConfigRequest',
    as ArrayRef[GetVodConfigRequest()];

coerce 'RepeatedGetVodConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::GetVodConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetVodConfigRequest',
    as HashRef[GetVodConfigRequest()];

declare 'DeleteVodConfigRequest',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::VideoStitcherService::DeleteVodConfigRequest'];

coerce 'DeleteVodConfigRequest',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::DeleteVodConfigRequest'->new($_) };

declare 'RepeatedDeleteVodConfigRequest',
    as ArrayRef[DeleteVodConfigRequest()];

coerce 'RepeatedDeleteVodConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::DeleteVodConfigRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteVodConfigRequest',
    as HashRef[DeleteVodConfigRequest()];

declare 'UpdateVodConfigRequest',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::VideoStitcherService::UpdateVodConfigRequest'];

coerce 'UpdateVodConfigRequest',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::UpdateVodConfigRequest'->new($_) };

declare 'RepeatedUpdateVodConfigRequest',
    as ArrayRef[UpdateVodConfigRequest()];

coerce 'RepeatedUpdateVodConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::UpdateVodConfigRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateVodConfigRequest',
    as HashRef[UpdateVodConfigRequest()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::VideoStitcherService::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::VideoStitcherService::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Video::Stitcher::V1::VideoStitcherService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
