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

use 5.014;
use utf8;
use autodie;
use warnings;
use open ':utf8';
use JIRA::Client;
use Data::Dumper;
use Getopt::Long;

my $usage = "$0 [--projects] [--verbose] JIRAURL USER PASS\n";
my $Projects;
my $Verbose;
GetOptions(
    'projects+' => \$Projects,
    'verbose+'  => \$Verbose,
) or die $usage;

@ARGV == 3 or die "usage: $usage\n";

my $jira = JIRA::Client->new(@ARGV);

sub hash_of {
    my ($array, $key) = @_;
    $key //= 'name';
    my %hash;
    foreach my $e (@$array) {
	$hash{$e->{$key}} = $e;
    }
    return \%hash;
}

my %JIRA = (
    Configuration     => $jira->getConfiguration(),
    CustomFields      => hash_of($jira->getCustomFields()),
    FavouriteFilters  => hash_of($jira->getFavouriteFilters()),
    IssueTypes 	      => hash_of($jira->getIssueTypes()),
    Permissions       => hash_of($jira->getAllPermissions()),
    Priorities 	      => hash_of($jira->getPriorities()),
    Projects          => hash_of($jira->getProjectsNoSchemes(), 'key'),
    Resolutions       => hash_of($jira->getResolutions()),
    ServerInfo        => $jira->getServerInfo(),
    Statuses          => hash_of($jira->getStatuses()),
    SubTaskIssueTypes => hash_of($jira->getSubTaskIssueTypes()),
);

if ($Projects) {
    warn "Grokking ", scalar(keys %{$JIRA{Projects}}), " projects:\n" if $Verbose;
    foreach my $key (sort keys %{$JIRA{Projects}}) {
	warn "Grokking project $key\n" if $Verbose;
	my $project = $JIRA{Projects}{$key};
	$project->{info} = {
	    Components 	      => hash_of($jira->getComponents($key)),
#	    IssueTypes 	      => hash_of(jira->getIssueTypesForProject($key)),
#	    Avatars    	      => hash_of(jira->getProjectAvatars($key, 0)),
#	    SecurityLevels    => hash_of(jira->getSecurityLevels($key)),
#	    SubTaskIssueTypes => hash_of(jira->getSubTaskIssueTypesForProject($key)),
	    Versions          => hash_of($jira->getVersions($key)),
	};
    }
}

$Data::Dumper::Indent = 1;
$Data::Dumper::Sortkeys = 1;

say Dumper(\%JIRA);
