#!/usr/bin/perl
use strict;
use warnings;
#this script serves as a simple test of the API

require 'lib/LabKey/Query.pm';
#use LabKey::Query;
use Data::Dumper;

# Create and configure a UserAgent once for multiple requests
#use LWP::UserAgent;
#my $ua = new LWP::UserAgent;

my $results = LabKey::Query::selectRows(
    -baseUrl => 'http://localhost:8080/labkey/',
    -containerPath => 'home/',
    -schemaName => 'core',
    -queryName => 'Containers',
    -maxRows => 2,
    #-sort => '-userid',
    -debug => 1,
    -loginAsGuest => 1,
    #-timeout => 0.01,
    #-useragent => $ua
    );
#print Dumper($results);
print Dumper($$results{'rows'});

#it seems guests cannot run executeSql
#my $sql = LabKey::Query::executeSql(
#   -baseUrl => 'https://www.labkey.org/',
#   -containerPath => 'home/Documentation/',
#   -schemaName => 'issues',
#   -sql => 'SELECT max(i.issueid) as id FROM issues.issues i',
#   -debug => 1,
#   -loginAsGuest => 1,
#   );
#
#print Dumper($sql);
