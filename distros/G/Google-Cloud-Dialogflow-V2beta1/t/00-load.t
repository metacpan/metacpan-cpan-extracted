#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 23;

BEGIN {
    use_ok( 'Google::Cloud::Dialogflow::V2beta1' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::V2beta1::AgentsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::V2beta1::AnswerRecordsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::V2beta1::CompanionAgentsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::V2beta1::ContextsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::V2beta1::ConversationProfilesClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::V2beta1::ConversationsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::V2beta1::DocumentsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::V2beta1::EncryptionSpecServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::V2beta1::EntityTypesClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::V2beta1::EnvironmentsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::V2beta1::FulfillmentsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::V2beta1::GeneratorEvaluationsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::V2beta1::GeneratorsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::V2beta1::IntentsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::V2beta1::KnowledgeBasesClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::V2beta1::ParticipantsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::V2beta1::PhoneNumbersClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::V2beta1::SessionEntityTypesClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::V2beta1::SessionsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::V2beta1::SipTrunksClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::V2beta1::ToolsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::V2beta1::VersionsClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Dialogflow::V2beta1 $Google::Cloud::Dialogflow::V2beta1::VERSION, Perl $], $^X" );
