#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use File::Temp;
use File::Spec;

BEGIN {
    use_ok('JIRA::Client::Automated');
}

# Set JIRA access information in ENV vars or pass it to the test.
my $jira_server   = $ENV{JIRA_CLIENT_AUTOMATED_URL}      || $ARGV[0];
my $jira_project  = $ENV{JIRA_CLIENT_AUTOMATED_PROJECT}  || $ARGV[1];
my $jira_user     = $ENV{JIRA_CLIENT_AUTOMATED_USER}     || $ARGV[2];
my $jira_password = $ENV{JIRA_CLIENT_AUTOMATED_PASSWORD} || $ARGV[3];

SKIP: {

    my $skip_text = <<END_SKIP_TEXT;
You must provide a URL for a JIRA server, project name, username and password in the appropriate environment variables to run this test.
For example:
setenv JIRA_CLIENT_AUTOMATED_URL 'https://you.atlassian.net/'
setenv JIRA_CLIENT_AUTOMATED_PROJECT TEST
setenv JIRA_CLIENT_AUTOMATED_USER you
setenv JIRA_CLIENT_AUTOMATED_PASSWORD '******'
END_SKIP_TEXT

    skip $skip_text, 1 if (!($jira_server && $jira_project && $jira_user && $jira_password));

    my $JCA = 'JIRA::Client::Automated';
    my ($jira, $issue, $key, @issues, $link_types);

    # Create new JCA object
    ok($jira = JIRA::Client::Automated->new($jira_server, $jira_user, $jira_password), 'new');
    isa_ok($jira, $JCA);

    # --- read-only tests first

    # check search that returns no matches
    @issues = $jira->all_search_results('createdDate = "1971-01-01"', 10);
    is @issues, 0, 'all_search_results with no results';
    
    @issues = $jira->all_search_results('KEY = NONESUCH-999999', 10);
    is @issues, 0, 'all_search_results with invalid key';

    # save link_types for later testing
    ok($link_types = $jira->get_link_types(), 'get_link_types');
    cmp_ok( (grep { $_->{name} eq 'Blocks' } @$link_types), '>=', 1, 'has blocks link type');
    
    # --- read-only tests first

    # Create an issue
    $issue = $jira->create_issue(
        $jira_project, 'Bug',
        "$JCA Test Script",
        "Created by $JCA Test Script automatically.",
        { labels => ["Commentary"] });
    ok($issue, 'create_issue');
    isa_ok($issue, 'HASH');
    ok($key   = $issue->{key},          'create_issue key');
    ok($issue = $jira->get_issue($key), 'get_issue');
    is($issue->{fields}{summary},     "$JCA Test Script",                           'create_issue summary');
    is($issue->{fields}{description}, "Created by $JCA Test Script automatically.", 'create_issue description');
    is($issue->{fields}{labels}[0],   "Commentary",                                 'create_issue labels');
    {
        my $browse_url = $jira->make_browse_url($key);
        ok(($browse_url =~ m{browse/$key$} and $browse_url !~ m{rest/api}),
            "make_browse_url");
    }

    # Comment on an issue
    my ($comments);
    ok($jira->create_comment($key, "Comment from $JCA Test Script."), 'create_comment');
    ok($comments = $jira->get_issue_comments($key), 'get_issue_comments');
    is($comments->[0]{body}, "Comment from $JCA Test Script.", 'create_comment worked');

    # Update an issue
    ok($jira->update_issue($key, { summary => "$JCA updated" }), 'update_issue');
    ok($issue = $jira->get_issue($key), 'get_issue to see update');
    is($issue->{fields}{summary}, "$JCA updated", 'update_issue summary');

    # Label an issue
    ok($jira->add_issue_labels($key, 'testing'), 'add_issue_labels');
    ok($issue = $jira->get_issue($key), 'get_issue to see add_issue_labels');
    is(grep(m/^testing$/, @{$issue->{fields}{labels}}), 1, 'add_issue_labels worked');
    ok($jira->remove_issue_labels($key, 'testing'), 'remove_issue_labels');
    ok($issue = $jira->get_issue($key), 'get_issue to see remove_issue_labels');
    is(grep(m/^testing$/, @{$issue->{fields}{labels}}), 0, 'remove _issue_labels worked');

    # Attach a file to an issue
    my $tmp = File::Temp->new();
    print $tmp "Attach this file to $JCA test issue $key.\n";
    close $tmp;
    my $filepath = $tmp->filename();
    my ($volume, $directories, $filename) = File::Spec->splitpath($filepath);

    ok($jira->attach_file_to_issue($key, $tmp->filename()), 'attach_file_to_issue');
    ok($issue = $jira->get_issue($key), 'get_issue to see attachment');
    is($issue->{fields}{attachment}[0]{filename}, $filename, 'attach_file_to_issue attachment');
    undef $tmp; # File::Temp unlinks the file when it goes out of scope

    # NOTE: these user-based tests may not do much, if your system auto-assigns
    # issues to the creator, but they are at least testing the API calls. 
    # add watcher
    my ($watchers);
    is($jira->add_issue_watchers($key, $jira_user), undef, 'add_issue_watchers');
    ok($watchers = $jira->get_issue_watchers($key), 'get_issue_watchers');
    is($watchers->[0]{name}, $jira_user, 'added watcher');

    # assign issue
    ok($jira->assign_issue($key, $jira_user), 'assign_issue');
    ok($issue = $jira->get_issue($key), 'get_issue to see assignee');
    is($issue->{fields}{assignee}{name}, $jira_user, 'assigned issue');

    # Transition tests
    throws_ok {
        $jira->transition_issue($key, 'NoneSuch Foo');
    }
    qr/has no transition.*NoneSuch Foo/, 'transition_issue with unknown name';
    throws_ok {
        $jira->transition_issue($key, ['NoneSuch Bar', 'NoneSuch Baz']);
    }
    qr/has no transition.*NoneSuch Bar.*NoneSuch Baz/, 'transition_issue with unknown names';

    # Transition an issue through its workflow
    my $transition_alternatives = ['Start Progress', 'Add to backlog', 'Open'];
    my $prev_status_name = $issue->{fields}{status}{name};
    ok($jira->transition_issue($key, $transition_alternatives), 'transition_issue');
    ok($issue = $jira->get_issue($key), 'get_issue to see transition');
    isnt($issue->{fields}{status}{name},
        $prev_status_name, "transition_issue status (now $issue->{fields}{status}{name})");

    # test worklog
    my $worklogs;
    is_deeply($worklogs = $jira->get_issue_worklogs($key), [], 'get_issue_worklogs no worklogs');
    my $sample_worklog = {
        "comment" => "I did some work here.",
        "started" => "2016-05-27T02:32:26.797+0000",
        "timeSpentSeconds" => 12000,
    };
    is($jira->add_issue_worklog($key, $sample_worklog), undef, 'add_issue_worklog');
    ok($worklogs = $jira->get_issue_worklogs($key), 'get_issue_worklogs with worklogs');
    is($worklogs->[0]->{comment}, $sample_worklog->{comment}, 'got worklog we added');

    # Search for issues
    # complicated queries work too:
    #    my $jql
    #      = 'project = '
    #      . $self->{_jira_project}
    #      . ' AND resolution in (Fixed, "Won\'t Fix", Duplicate, Incomplete, "Cannot Reproduce") '
    #      . 'AND issuetype = "Broken Crawler" '
    #      . 'AND status in (Verify, "Copy Crawler to Polyvore") '
    #      . 'AND reporter in (pv_eng) '
    #      . 'ORDER BY createdDate DESC';
    my $jql = "KEY = $key";
    ok(@issues = $jira->all_search_results($jql, 10), 'all_search_results');
    is($issues[0]->{key}, $key, 'all_search_results found issue');

    # Create a sub-task
    my ($subtask, $sub_key);
    ok( $subtask = $jira->create_subtask(
            $jira_project,
            "$JCA Test Subtask",
            "Created by $JCA Test Script automatically.",
            $issue->{key}
        ),
        'create_subtask'
    );
    isa_ok($subtask, 'HASH');
    ok($sub_key = $subtask->{key},            'create_subtask key');
    ok($subtask = $jira->get_issue($sub_key), 'get_issue subtask');
    is($subtask->{fields}{summary}, "$JCA Test Subtask", 'create_subtask summary');
    is($subtask->{fields}{description}, "Created by $JCA Test Script automatically.", 'create_subtask description');
    ok($jira->delete_issue($sub_key), 'delete_issue subtask');

    ok( $subtask = $jira->create_subtask(
            $jira_project,                                "$JCA Test Subtask",
            "Created by $JCA Test Script automatically.", $issue->{key},
            'Sub-task'
        ),
        'create_subtask with type'
    );
    isa_ok($subtask, 'HASH');
    ok($sub_key = $subtask->{key},            'create_subtask with type key');
    ok($subtask = $jira->get_issue($sub_key), 'get_issue subtask with type');

    # Link two issues
    is($jira->link_issues($issue->{key}, $subtask->{key}, $link_types->[0]->{name}), undef, 'link_issues');
    ok($subtask = $jira->get_issue($sub_key), 'get_issue subtask to check link worked');
    my $issuelink = $subtask->{fields}{issuelinks}[0];
    is($issuelink->{type}{name}, $link_types->[0]->{name}, 'created correct type of link');
    is($issuelink->{outwardIssue}{key}, $issue->{key}, 'linked to correct issue');

    # Delete sub-task
    ok($jira->delete_issue($sub_key), 'delete_issue subtask');

    # Close an issue
    ok($jira->close_issue($key, 'Fixed', "Closed by $JCA Test Script"), 'close_issue');
    ok($issue = $jira->get_issue($key), 'get_issue to see closed');
    is($issue->{fields}{status}{name}, 'Closed', 'close_issue status');

    # Delete our test issue
    # You wouldn't want to do this in production; they're handy to keep around as documentation
    # May fail with 403 Forbidden
    ok($jira->delete_issue($key), 'delete_issue');
    throws_ok { @issues = $jira->all_search_results($jql, 10) } qr/does not exist/, 'all_search_results after delete';
}

done_testing()
