# Hey Emacs, this is -*- perl -*-
use strict;
use warnings;
use Test::More;
use JIRA::Client;

my $democonf = $ENV{DEMOCONF} || 't/demo-atlassian.conf';

unless (defined $democonf) {
    plan skip_all => 'Demo tests are disabled.';
}

unless (-r $democonf) {
    plan skip_all => "DEMOCONF ($democonf) does not exist or is unreadable.";
}

my $conf = do $democonf;
unless ($conf) {
    plan skip_all => "couldn't parse $democonf: $@" if $@;
    plan skip_all => "couldn't do $democonf: $!"    unless defined $conf;
    plan skip_all => "couldn't run $democonf"       unless $conf;
}
plan skip_all => "$democonf does not return a hash-ref" unless ref $conf and ref $conf eq 'HASH';
plan skip_all => "$democonf does not define a password" unless defined $conf->{pass};

my $jira = eval {JIRA::Client->new({
    baseurl  => $conf->{url},
    user     => $conf->{user},
    password => $conf->{pass},
})};

ok(defined $jira, 'new returns')
    and ok(ref $jira, 'new returns an object')
    and is(ref $jira, 'JIRA::Client', 'new returns a correct object')
    or BAIL_OUT("Cannot proceed without a JIRA::Client object: $@\n");

my $issue = eval {$jira->create_issue({
    project  => $conf->{project},
    assignee => $conf->{user},
    %{$conf->{issue}},
})};

ok(defined $issue, 'create_issue returns')
    and ok(ref $issue, 'create_issue returns an object')
    and is(ref $issue, 'RemoteIssue', "create_issue returns a RemoteIssue object (https://jira.atlassian.com/browse/$issue->{key})")
    or BAIL_OUT("Cannot proceed because I cannot create an issue: $@\n");

my $rissue = eval {$jira->getIssue($issue->{key})};

ok(defined $rissue, 'getIssue returns')
    and ok(ref $rissue, 'getIssue returns an object')
    and is(ref $rissue, 'RemoteIssue', 'getIssue returns a RemoteIssue object')
    and is($rissue->{key}, $issue->{key}, 'getIssue returns the correct issue')
    or BAIL_OUT("Cannot proceed because I cannot get anything from the server: $@\n");

my $subissue = eval {$jira->create_issue({
    project  => $conf->{project},
    assignee => $conf->{user},
    parent   => $issue->{key},
    %{$conf->{subtask}},
})};

ok(defined $subissue, 'create_issue sub-task returns')
    and ok(ref $subissue, 'create_issue sub-task returns an object')
    and is(ref $subissue, 'RemoteIssue', "create_issue sub-task returns a RemoteIssue object (http://sandbox.onjira.com/browse/$subissue->{key})")
    or BAIL_OUT("Cannot proceed because I cannot create an sub-task issue: $@\n");

foreach my $progress (@{$conf->{subtask_progress}}) {
    my $pissue = eval {$jira->progress_workflow_action_safely($subissue, @$progress)};
    my $prefix = "progress_workflow_action_safely(sub-task, $progress->[0])";
    ok(defined $pissue, "$prefix returns")
	and ok(ref $pissue, "$prefix returns an object")
	    and is(ref $pissue, 'RemoteIssue', "$prefix returns a RemoteIssue object")
		and isnt($pissue->{status}, $progress->[0], "$prefix progressed the issue");
    $subissue = $pissue;
}

foreach my $progress (@{$conf->{issue_progress}}) {
    my $pissue = eval {$jira->progress_workflow_action_safely($issue, @$progress)};
    my $prefix = "progress_workflow_action_safely(issue, $progress->[0])";
    ok(defined $pissue, "$prefix returns")
	and ok(ref $pissue, "$prefix returns an object")
	    and is(ref $pissue, 'RemoteIssue', "$prefix returns a RemoteIssue object")
		and isnt($pissue->{status}, $progress->[0], "$prefix progressed the issue");
    $issue = $pissue;
}

done_testing();
