#!/usr/bin/env perl

# Sample Perl client accessing JIRA via SOAP using the CPAN
# JIRA::Client module. This is mostly a translation of the Python
# client example at
# http://confluence.atlassian.com/display/JIRA/Creating+a+SOAP+Client.

use strict;
use warnings;
use Data::Dumper;
use DateTime;
use JIRA::Client;

my $jirauser = 'soaptester';
my $passwd   = 'soaptester';

my $jira = JIRA::Client->new('http://jira.atlassian.com/', $jirauser, $passwd);

my $issue = $jira->getIssue('TST-3410');
print "Retrieved issue:", Dumper($issue), "\n";

my $baseurl = $jira->getServerInfo()->{baseUrl};

# Note: JIRA::Client's create_issue method encapsulates the API's
# createIssue, dealing with several name convertions such as issue
# types, versions, components, dates, and custom fields. It's usually
# much easier to use than the bare method directly.
#
# These name conversions are performed with implicit calls to the
# get_* API methods. They usually require administrative priviledges
# to get called. Be warned!
my $newissue = $jira->create_issue({
    project => 'TST',
    type    => 'Bug',
    summary => 'Issue created with Perl!'
});
print "Created $baseurl/browse/$newissue->{key}\n";

print "Adding comment..\n";
# Note: JIRA::Client converts transparently addComment's first
# argument from a RemoteIssue object into an issue key and its second
# argument from a string into a RemoteComment object. This kind of
# implicit conversion is performed for several methods, making it
# easier to use the API.
$jira->addComment($newissue, 'Comment added with SOAP');

print "Updating issue..\n";
# Note: JIRA::Client's update_issue method encapsulates the API's
# updateIssue, in much the same way as create_issue encapsulates
# createIssue above. Note that duedate's value may be specified with a
# DateTime object. Also note how you can specify custom fields by
# name.
$jira->update_issue(
    $newissue,
    {
	summary       => '[Updated] Issue created with Perl',
	type          => 'New feature',
	fixVersions   => '1.0.1',
	duedate       => DateTime->today->add(days => 3),
	custom_fields => {
	    'Client'   => 'CPqD',
	    'Location' => 'Campinas',
	},
    },
);

print "Resolving issue..\n";
# Note: JIRA::Client's progress_workflow_action_safely method
# encapsulates the API's progressWorkflowAction in much the same way
# as create_issue encapsulates createIssue above. It also avoids the
# need to specify values for all the screen values, lest the
# unspecified ones be undefined as a result. Non-specified fields have
# their current values fetched from the Issue and inserted in the
# paramenters to progressWorkflowAction.
$jira->progress_workflow_action_safely(
    $newissue,
    'Resolve Issue',
    {
	assigne     => 'jefft',
	fixVersions => '1.1.0',
	resolution  => "Won't Fix",
    },
);


# This works if you have the right permissions
my $user = $jira->createUser("testuser2", "testuser2", "SOAP-created user", 'newuser@localhost');
print "Created user $user\n";

my $group = $jira->getGroup("jira-developers");
$jira->addUserToGroup($group, $user);

$jira->addVersion("TST", {name => 'Version 1'});

print "Done!\n";
