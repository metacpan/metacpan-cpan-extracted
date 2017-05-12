package Microsoft::AdCenter::V8::ReportingService::Test::KeywordMigrationReportRequest;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::ReportingService;
use Microsoft::AdCenter::V8::ReportingService::KeywordMigrationReportRequest;

sub test_can_create_keyword_migration_report_request_and_set_all_fields : Test(3) {
    my $keyword_migration_report_request = Microsoft::AdCenter::V8::ReportingService::KeywordMigrationReportRequest->new
        ->Columns('columns')
        ->Scope('scope')
    ;

    ok($keyword_migration_report_request);

    is($keyword_migration_report_request->Columns, 'columns', 'can get columns');
    is($keyword_migration_report_request->Scope, 'scope', 'can get scope');
};

1;
