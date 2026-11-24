package Google::Cloud::Dialogflow::Cx::V3::TestCase::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'TestResult',
    as (Int | Str);

declare 'TestCase',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::TestCase::TestCase'];

coerce 'TestCase',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::TestCase'->new($_) };

declare 'RepeatedTestCase',
    as ArrayRef[TestCase()];

coerce 'RepeatedTestCase',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::TestCase'->new($_) } @$_ ] };

declare 'MapStringTestCase',
    as HashRef[TestCase()];

declare 'TestCaseResult',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::TestCase::TestCaseResult'];

coerce 'TestCaseResult',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::TestCaseResult'->new($_) };

declare 'RepeatedTestCaseResult',
    as ArrayRef[TestCaseResult()];

coerce 'RepeatedTestCaseResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::TestCaseResult'->new($_) } @$_ ] };

declare 'MapStringTestCaseResult',
    as HashRef[TestCaseResult()];

declare 'TestConfig',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::TestCase::TestConfig'];

coerce 'TestConfig',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::TestConfig'->new($_) };

declare 'RepeatedTestConfig',
    as ArrayRef[TestConfig()];

coerce 'RepeatedTestConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::TestConfig'->new($_) } @$_ ] };

declare 'MapStringTestConfig',
    as HashRef[TestConfig()];

declare 'ConversationTurn',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::TestCase::ConversationTurn'];

coerce 'ConversationTurn',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::ConversationTurn'->new($_) };

declare 'RepeatedConversationTurn',
    as ArrayRef[ConversationTurn()];

coerce 'RepeatedConversationTurn',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::ConversationTurn'->new($_) } @$_ ] };

declare 'MapStringConversationTurn',
    as HashRef[ConversationTurn()];

declare 'UserInput',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::TestCase::ConversationTurn::UserInput'];

coerce 'UserInput',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::ConversationTurn::UserInput'->new($_) };

declare 'RepeatedUserInput',
    as ArrayRef[UserInput()];

coerce 'RepeatedUserInput',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::ConversationTurn::UserInput'->new($_) } @$_ ] };

declare 'MapStringUserInput',
    as HashRef[UserInput()];

declare 'VirtualAgentOutput',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::TestCase::ConversationTurn::VirtualAgentOutput'];

coerce 'VirtualAgentOutput',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::ConversationTurn::VirtualAgentOutput'->new($_) };

declare 'RepeatedVirtualAgentOutput',
    as ArrayRef[VirtualAgentOutput()];

coerce 'RepeatedVirtualAgentOutput',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::ConversationTurn::VirtualAgentOutput'->new($_) } @$_ ] };

declare 'MapStringVirtualAgentOutput',
    as HashRef[VirtualAgentOutput()];

declare 'TestRunDifference',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::TestCase::TestRunDifference'];

coerce 'TestRunDifference',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::TestRunDifference'->new($_) };

declare 'RepeatedTestRunDifference',
    as ArrayRef[TestRunDifference()];

coerce 'RepeatedTestRunDifference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::TestRunDifference'->new($_) } @$_ ] };

declare 'MapStringTestRunDifference',
    as HashRef[TestRunDifference()];

declare 'DiffType',
    as (Int | Str);

declare 'TransitionCoverage',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::TestCase::TransitionCoverage'];

coerce 'TransitionCoverage',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::TransitionCoverage'->new($_) };

declare 'RepeatedTransitionCoverage',
    as ArrayRef[TransitionCoverage()];

coerce 'RepeatedTransitionCoverage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::TransitionCoverage'->new($_) } @$_ ] };

declare 'MapStringTransitionCoverage',
    as HashRef[TransitionCoverage()];

declare 'TransitionNode',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::TestCase::TransitionCoverage::TransitionNode'];

coerce 'TransitionNode',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::TransitionCoverage::TransitionNode'->new($_) };

declare 'RepeatedTransitionNode',
    as ArrayRef[TransitionNode()];

coerce 'RepeatedTransitionNode',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::TransitionCoverage::TransitionNode'->new($_) } @$_ ] };

declare 'MapStringTransitionNode',
    as HashRef[TransitionNode()];

declare 'Transition',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::TestCase::TransitionCoverage::Transition'];

coerce 'Transition',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::TransitionCoverage::Transition'->new($_) };

declare 'RepeatedTransition',
    as ArrayRef[Transition()];

coerce 'RepeatedTransition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::TransitionCoverage::Transition'->new($_) } @$_ ] };

declare 'MapStringTransition',
    as HashRef[Transition()];

declare 'TransitionRouteGroupCoverage',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::TestCase::TransitionRouteGroupCoverage'];

coerce 'TransitionRouteGroupCoverage',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::TransitionRouteGroupCoverage'->new($_) };

declare 'RepeatedTransitionRouteGroupCoverage',
    as ArrayRef[TransitionRouteGroupCoverage()];

coerce 'RepeatedTransitionRouteGroupCoverage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::TransitionRouteGroupCoverage'->new($_) } @$_ ] };

declare 'MapStringTransitionRouteGroupCoverage',
    as HashRef[TransitionRouteGroupCoverage()];

declare 'Coverage',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::TestCase::TransitionRouteGroupCoverage::Coverage'];

coerce 'Coverage',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::TransitionRouteGroupCoverage::Coverage'->new($_) };

declare 'RepeatedCoverage',
    as ArrayRef[Coverage()];

coerce 'RepeatedCoverage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::TransitionRouteGroupCoverage::Coverage'->new($_) } @$_ ] };

declare 'MapStringCoverage',
    as HashRef[Coverage()];

declare 'Transition',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::TestCase::TransitionRouteGroupCoverage::Coverage::Transition'];

coerce 'Transition',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::TransitionRouteGroupCoverage::Coverage::Transition'->new($_) };

declare 'RepeatedTransition',
    as ArrayRef[Transition()];

coerce 'RepeatedTransition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::TransitionRouteGroupCoverage::Coverage::Transition'->new($_) } @$_ ] };

declare 'MapStringTransition',
    as HashRef[Transition()];

declare 'IntentCoverage',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::TestCase::IntentCoverage'];

coerce 'IntentCoverage',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::IntentCoverage'->new($_) };

declare 'RepeatedIntentCoverage',
    as ArrayRef[IntentCoverage()];

coerce 'RepeatedIntentCoverage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::IntentCoverage'->new($_) } @$_ ] };

declare 'MapStringIntentCoverage',
    as HashRef[IntentCoverage()];

declare 'Intent',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::TestCase::IntentCoverage::Intent'];

coerce 'Intent',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::IntentCoverage::Intent'->new($_) };

declare 'RepeatedIntent',
    as ArrayRef[Intent()];

coerce 'RepeatedIntent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::IntentCoverage::Intent'->new($_) } @$_ ] };

declare 'MapStringIntent',
    as HashRef[Intent()];

declare 'CalculateCoverageRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::TestCase::CalculateCoverageRequest'];

coerce 'CalculateCoverageRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::CalculateCoverageRequest'->new($_) };

declare 'RepeatedCalculateCoverageRequest',
    as ArrayRef[CalculateCoverageRequest()];

coerce 'RepeatedCalculateCoverageRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::CalculateCoverageRequest'->new($_) } @$_ ] };

declare 'MapStringCalculateCoverageRequest',
    as HashRef[CalculateCoverageRequest()];

declare 'CoverageType',
    as (Int | Str);

declare 'CalculateCoverageResponse',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::TestCase::CalculateCoverageResponse'];

coerce 'CalculateCoverageResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::CalculateCoverageResponse'->new($_) };

declare 'RepeatedCalculateCoverageResponse',
    as ArrayRef[CalculateCoverageResponse()];

coerce 'RepeatedCalculateCoverageResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::CalculateCoverageResponse'->new($_) } @$_ ] };

declare 'MapStringCalculateCoverageResponse',
    as HashRef[CalculateCoverageResponse()];

declare 'ListTestCasesRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::TestCase::ListTestCasesRequest'];

coerce 'ListTestCasesRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::ListTestCasesRequest'->new($_) };

declare 'RepeatedListTestCasesRequest',
    as ArrayRef[ListTestCasesRequest()];

coerce 'RepeatedListTestCasesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::ListTestCasesRequest'->new($_) } @$_ ] };

declare 'MapStringListTestCasesRequest',
    as HashRef[ListTestCasesRequest()];

declare 'TestCaseView',
    as (Int | Str);

declare 'ListTestCasesResponse',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::TestCase::ListTestCasesResponse'];

coerce 'ListTestCasesResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::ListTestCasesResponse'->new($_) };

declare 'RepeatedListTestCasesResponse',
    as ArrayRef[ListTestCasesResponse()];

coerce 'RepeatedListTestCasesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::ListTestCasesResponse'->new($_) } @$_ ] };

declare 'MapStringListTestCasesResponse',
    as HashRef[ListTestCasesResponse()];

declare 'BatchDeleteTestCasesRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::TestCase::BatchDeleteTestCasesRequest'];

coerce 'BatchDeleteTestCasesRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::BatchDeleteTestCasesRequest'->new($_) };

declare 'RepeatedBatchDeleteTestCasesRequest',
    as ArrayRef[BatchDeleteTestCasesRequest()];

coerce 'RepeatedBatchDeleteTestCasesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::BatchDeleteTestCasesRequest'->new($_) } @$_ ] };

declare 'MapStringBatchDeleteTestCasesRequest',
    as HashRef[BatchDeleteTestCasesRequest()];

declare 'CreateTestCaseRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::TestCase::CreateTestCaseRequest'];

coerce 'CreateTestCaseRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::CreateTestCaseRequest'->new($_) };

declare 'RepeatedCreateTestCaseRequest',
    as ArrayRef[CreateTestCaseRequest()];

coerce 'RepeatedCreateTestCaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::CreateTestCaseRequest'->new($_) } @$_ ] };

declare 'MapStringCreateTestCaseRequest',
    as HashRef[CreateTestCaseRequest()];

declare 'UpdateTestCaseRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::TestCase::UpdateTestCaseRequest'];

coerce 'UpdateTestCaseRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::UpdateTestCaseRequest'->new($_) };

declare 'RepeatedUpdateTestCaseRequest',
    as ArrayRef[UpdateTestCaseRequest()];

coerce 'RepeatedUpdateTestCaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::UpdateTestCaseRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateTestCaseRequest',
    as HashRef[UpdateTestCaseRequest()];

declare 'GetTestCaseRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::TestCase::GetTestCaseRequest'];

coerce 'GetTestCaseRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::GetTestCaseRequest'->new($_) };

declare 'RepeatedGetTestCaseRequest',
    as ArrayRef[GetTestCaseRequest()];

coerce 'RepeatedGetTestCaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::GetTestCaseRequest'->new($_) } @$_ ] };

declare 'MapStringGetTestCaseRequest',
    as HashRef[GetTestCaseRequest()];

declare 'RunTestCaseRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::TestCase::RunTestCaseRequest'];

coerce 'RunTestCaseRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::RunTestCaseRequest'->new($_) };

declare 'RepeatedRunTestCaseRequest',
    as ArrayRef[RunTestCaseRequest()];

coerce 'RepeatedRunTestCaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::RunTestCaseRequest'->new($_) } @$_ ] };

declare 'MapStringRunTestCaseRequest',
    as HashRef[RunTestCaseRequest()];

declare 'RunTestCaseResponse',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::TestCase::RunTestCaseResponse'];

coerce 'RunTestCaseResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::RunTestCaseResponse'->new($_) };

declare 'RepeatedRunTestCaseResponse',
    as ArrayRef[RunTestCaseResponse()];

coerce 'RepeatedRunTestCaseResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::RunTestCaseResponse'->new($_) } @$_ ] };

declare 'MapStringRunTestCaseResponse',
    as HashRef[RunTestCaseResponse()];

declare 'RunTestCaseMetadata',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::TestCase::RunTestCaseMetadata'];

coerce 'RunTestCaseMetadata',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::RunTestCaseMetadata'->new($_) };

declare 'RepeatedRunTestCaseMetadata',
    as ArrayRef[RunTestCaseMetadata()];

coerce 'RepeatedRunTestCaseMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::RunTestCaseMetadata'->new($_) } @$_ ] };

declare 'MapStringRunTestCaseMetadata',
    as HashRef[RunTestCaseMetadata()];

declare 'BatchRunTestCasesRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::TestCase::BatchRunTestCasesRequest'];

coerce 'BatchRunTestCasesRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::BatchRunTestCasesRequest'->new($_) };

declare 'RepeatedBatchRunTestCasesRequest',
    as ArrayRef[BatchRunTestCasesRequest()];

coerce 'RepeatedBatchRunTestCasesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::BatchRunTestCasesRequest'->new($_) } @$_ ] };

declare 'MapStringBatchRunTestCasesRequest',
    as HashRef[BatchRunTestCasesRequest()];

declare 'BatchRunTestCasesResponse',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::TestCase::BatchRunTestCasesResponse'];

coerce 'BatchRunTestCasesResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::BatchRunTestCasesResponse'->new($_) };

declare 'RepeatedBatchRunTestCasesResponse',
    as ArrayRef[BatchRunTestCasesResponse()];

coerce 'RepeatedBatchRunTestCasesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::BatchRunTestCasesResponse'->new($_) } @$_ ] };

declare 'MapStringBatchRunTestCasesResponse',
    as HashRef[BatchRunTestCasesResponse()];

declare 'BatchRunTestCasesMetadata',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::TestCase::BatchRunTestCasesMetadata'];

coerce 'BatchRunTestCasesMetadata',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::BatchRunTestCasesMetadata'->new($_) };

declare 'RepeatedBatchRunTestCasesMetadata',
    as ArrayRef[BatchRunTestCasesMetadata()];

coerce 'RepeatedBatchRunTestCasesMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::BatchRunTestCasesMetadata'->new($_) } @$_ ] };

declare 'MapStringBatchRunTestCasesMetadata',
    as HashRef[BatchRunTestCasesMetadata()];

declare 'TestError',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::TestCase::TestError'];

coerce 'TestError',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::TestError'->new($_) };

declare 'RepeatedTestError',
    as ArrayRef[TestError()];

coerce 'RepeatedTestError',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::TestError'->new($_) } @$_ ] };

declare 'MapStringTestError',
    as HashRef[TestError()];

declare 'ImportTestCasesRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::TestCase::ImportTestCasesRequest'];

coerce 'ImportTestCasesRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::ImportTestCasesRequest'->new($_) };

declare 'RepeatedImportTestCasesRequest',
    as ArrayRef[ImportTestCasesRequest()];

coerce 'RepeatedImportTestCasesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::ImportTestCasesRequest'->new($_) } @$_ ] };

declare 'MapStringImportTestCasesRequest',
    as HashRef[ImportTestCasesRequest()];

declare 'ImportTestCasesResponse',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::TestCase::ImportTestCasesResponse'];

coerce 'ImportTestCasesResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::ImportTestCasesResponse'->new($_) };

declare 'RepeatedImportTestCasesResponse',
    as ArrayRef[ImportTestCasesResponse()];

coerce 'RepeatedImportTestCasesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::ImportTestCasesResponse'->new($_) } @$_ ] };

declare 'MapStringImportTestCasesResponse',
    as HashRef[ImportTestCasesResponse()];

declare 'ImportTestCasesMetadata',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::TestCase::ImportTestCasesMetadata'];

coerce 'ImportTestCasesMetadata',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::ImportTestCasesMetadata'->new($_) };

declare 'RepeatedImportTestCasesMetadata',
    as ArrayRef[ImportTestCasesMetadata()];

coerce 'RepeatedImportTestCasesMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::ImportTestCasesMetadata'->new($_) } @$_ ] };

declare 'MapStringImportTestCasesMetadata',
    as HashRef[ImportTestCasesMetadata()];

declare 'TestCaseError',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::TestCase::TestCaseError'];

coerce 'TestCaseError',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::TestCaseError'->new($_) };

declare 'RepeatedTestCaseError',
    as ArrayRef[TestCaseError()];

coerce 'RepeatedTestCaseError',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::TestCaseError'->new($_) } @$_ ] };

declare 'MapStringTestCaseError',
    as HashRef[TestCaseError()];

declare 'ExportTestCasesRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::TestCase::ExportTestCasesRequest'];

coerce 'ExportTestCasesRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::ExportTestCasesRequest'->new($_) };

declare 'RepeatedExportTestCasesRequest',
    as ArrayRef[ExportTestCasesRequest()];

coerce 'RepeatedExportTestCasesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::ExportTestCasesRequest'->new($_) } @$_ ] };

declare 'MapStringExportTestCasesRequest',
    as HashRef[ExportTestCasesRequest()];

declare 'DataFormat',
    as (Int | Str);

declare 'ExportTestCasesResponse',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::TestCase::ExportTestCasesResponse'];

coerce 'ExportTestCasesResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::ExportTestCasesResponse'->new($_) };

declare 'RepeatedExportTestCasesResponse',
    as ArrayRef[ExportTestCasesResponse()];

coerce 'RepeatedExportTestCasesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::ExportTestCasesResponse'->new($_) } @$_ ] };

declare 'MapStringExportTestCasesResponse',
    as HashRef[ExportTestCasesResponse()];

declare 'ExportTestCasesMetadata',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::TestCase::ExportTestCasesMetadata'];

coerce 'ExportTestCasesMetadata',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::ExportTestCasesMetadata'->new($_) };

declare 'RepeatedExportTestCasesMetadata',
    as ArrayRef[ExportTestCasesMetadata()];

coerce 'RepeatedExportTestCasesMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::ExportTestCasesMetadata'->new($_) } @$_ ] };

declare 'MapStringExportTestCasesMetadata',
    as HashRef[ExportTestCasesMetadata()];

declare 'ListTestCaseResultsRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::TestCase::ListTestCaseResultsRequest'];

coerce 'ListTestCaseResultsRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::ListTestCaseResultsRequest'->new($_) };

declare 'RepeatedListTestCaseResultsRequest',
    as ArrayRef[ListTestCaseResultsRequest()];

coerce 'RepeatedListTestCaseResultsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::ListTestCaseResultsRequest'->new($_) } @$_ ] };

declare 'MapStringListTestCaseResultsRequest',
    as HashRef[ListTestCaseResultsRequest()];

declare 'ListTestCaseResultsResponse',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::TestCase::ListTestCaseResultsResponse'];

coerce 'ListTestCaseResultsResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::ListTestCaseResultsResponse'->new($_) };

declare 'RepeatedListTestCaseResultsResponse',
    as ArrayRef[ListTestCaseResultsResponse()];

coerce 'RepeatedListTestCaseResultsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::ListTestCaseResultsResponse'->new($_) } @$_ ] };

declare 'MapStringListTestCaseResultsResponse',
    as HashRef[ListTestCaseResultsResponse()];

declare 'GetTestCaseResultRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::TestCase::GetTestCaseResultRequest'];

coerce 'GetTestCaseResultRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::GetTestCaseResultRequest'->new($_) };

declare 'RepeatedGetTestCaseResultRequest',
    as ArrayRef[GetTestCaseResultRequest()];

coerce 'RepeatedGetTestCaseResultRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::TestCase::GetTestCaseResultRequest'->new($_) } @$_ ] };

declare 'MapStringGetTestCaseResultRequest',
    as HashRef[GetTestCaseResultRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3::TestCase::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
