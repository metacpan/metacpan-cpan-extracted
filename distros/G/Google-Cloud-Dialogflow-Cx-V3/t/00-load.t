#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 21;

BEGIN {
    use_ok( 'Google::Cloud::Dialogflow::Cx::V3' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::Cx::V3::AgentsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::Cx::V3::ChangelogsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::Cx::V3::DeploymentsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::Cx::V3::EntityTypesClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::Cx::V3::EnvironmentsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::Cx::V3::ExamplesClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::Cx::V3::ExperimentsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::Cx::V3::FlowsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::Cx::V3::GeneratorsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::Cx::V3::IntentsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::Cx::V3::PagesClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::Cx::V3::PlaybooksClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::Cx::V3::SecuritySettingsServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::Cx::V3::SessionEntityTypesClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::Cx::V3::SessionsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::Cx::V3::TestCasesClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::Cx::V3::ToolsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::Cx::V3::TransitionRouteGroupsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::Cx::V3::VersionsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dialogflow::Cx::V3::WebhooksClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Dialogflow::Cx::V3 $Google::Cloud::Dialogflow::Cx::V3::VERSION, Perl $], $^X" );
