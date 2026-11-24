#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 22;

BEGIN {
    use_ok( 'Google::Cloud::Dialogflow::Cx::V3beta1' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::Cx::V3beta1::AgentsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::Cx::V3beta1::ChangelogsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistoryClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::Cx::V3beta1::DeploymentsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::Cx::V3beta1::EntityTypesClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::Cx::V3beta1::EnvironmentsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::Cx::V3beta1::ExamplesClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::Cx::V3beta1::ExperimentsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::Cx::V3beta1::FlowsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::Cx::V3beta1::GeneratorsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::Cx::V3beta1::IntentsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::Cx::V3beta1::PagesClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::Cx::V3beta1::PlaybooksClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::Cx::V3beta1::SecuritySettingsServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::Cx::V3beta1::SessionEntityTypesClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::Cx::V3beta1::SessionsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::Cx::V3beta1::TestCasesClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::Cx::V3beta1::ToolsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::Cx::V3beta1::TransitionRouteGroupsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::Cx::V3beta1::VersionsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::Cx::V3beta1::WebhooksClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Dialogflow::Cx::V3beta1 $Google::Cloud::Dialogflow::Cx::V3beta1::VERSION, Perl $], $^X" );
