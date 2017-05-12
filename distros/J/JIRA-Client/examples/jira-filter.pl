#!/usr/bin/env perl

# Copyright (C) 2012 by CPqD

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use utf8;
use strict;
use warnings;
use open ':utf8';
use Getopt::Long;
use JIRA::Client;

my $usage = "$0 [--limit=LIMIT] JIRAURL JIRAUSER JIRAPASS FILTER\n";
my $Limit = 1000;
GetOptions(
    'limit=i' => \$Limit,
) or die $usage;

my ($Jiraurl, $Jirauser, $Jirapass, @filter) = @ARGV;

@filter or die "$usage\nMissing FILTER!\n";

my $Filter = join ' ', @filter;

sub jira_filter_issues {
    my ($jira, $filter, $limit) = @_;

    $filter =~ s/^\s*"?//;
    $filter =~ s/"?\s*$//;

    my $issues = do {
	if ($filter =~ /^(?:[A-Z]+-\d+\s+)*[A-Z]+-\d+$/i) {
	    # space separated key list
	    [map {$jira->getIssue(uc $_)} split / /, $filter];
	} elsif ($filter =~ /^[\w-]+$/i) {
	    # saved filter
	    $jira->getIssuesFromFilterWithLimit($filter, 0, $limit || 1000);
	} else {
	    # JQL filter
	    $jira->getIssuesFromJqlSearch($filter, $limit || 1000);
	}
    };

    # Order the issues by project key and then by numeric value using
    # a Schwartzian transform.
    map  {$_->[2]}
	sort {$a->[0] cmp $b->[0] or $a->[1] <=> $b->[1]}
	    map  {my ($p, $n) = ($_->{key} =~ /([A-Z]+)-(\d+)/); [$p, $n, $_]} @$issues;
}

my $jira = JIRA::Client->new($Jiraurl, $Jirauser, $Jirapass);

my @issues = jira_filter_issues($jira, $Filter, $Limit);

foreach my $issue (@issues) {
    print "$issue->{key}: $issue->{assignee}: '$issue->{summary}'\n";
}

__END__
=head1 NAME

jira-filter.pl - Lists the JIRA issues form a filter.

=head1 SYNOPSIS

jira-filter.pl [--limit=LIMIT] JIRAURL JIRAUSER JIRAPASS FILTER

=head1 DESCRIPTION

This script prints information about each issue found in JIRA matching
the specified filter.

FILTER can specify issues in three ways:

=over

=item KEY KEY KEY...

A space-separated list of issue keys.

=item JQL Expression

A JQL Expression (L<http://confluence.atlassian.com/display/JIRA/Advanced+Searching>).

=item Saved search filter

A saved search filter name (L<http://confluence.atlassian.com/display/JIRA/Saving+Searches+%28%27Issue+Filters%27%29>).

=back

=head1 OPTIONS

=over

=item --limit=LIMIT

This option limits the number of issues that the filter should
output. (Default is 1000.)

=back

=head1 SEE ALSO

=head1 COPYRIGHT

Copyright 2012 CPqD.

=head1 AUTHOR

Gustavo Chaves <gustavo@cpqd.com.br>
