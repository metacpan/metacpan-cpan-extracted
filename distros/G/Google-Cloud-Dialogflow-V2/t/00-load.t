#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 24;

BEGIN {
    use_ok( 'Google::Cloud::Dialogflow::V2' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::V2::AgentsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::V2::AnswerRecordsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::V2::CompanionAgentsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::V2::ContextsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::V2::ConversationDatasetsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::V2::ConversationModelsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::V2::ConversationProfilesClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::V2::ConversationsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::V2::DocumentsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::V2::EncryptionSpecServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::V2::EntityTypesClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::V2::EnvironmentsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::V2::FulfillmentsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::V2::GeneratorEvaluationsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::V2::GeneratorsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::V2::IntentsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::V2::KnowledgeBasesClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::V2::ParticipantsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::V2::SessionEntityTypesClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::V2::SessionsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::V2::SipTrunksClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::V2::ToolsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::V2::VersionsClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Dialogflow::V2 $Google::Cloud::Dialogflow::V2::VERSION, Perl $], $^X" );
