package Microsoft::AdCenter::V7::ReportingService::Test::NegativeKeywordConflictReportRequest;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V7::ReportingService;
use Microsoft::AdCenter::V7::ReportingService::NegativeKeywordConflictReportRequest;

sub test_can_create_negative_keyword_conflict_report_request_and_set_all_fields : Test(3) {
    my $negative_keyword_conflict_report_request = Microsoft::AdCenter::V7::ReportingService::NegativeKeywordConflictReportRequest->new
        ->Columns('columns')
        ->Scope('scope')
    ;

    ok($negative_keyword_conflict_report_request);

    is($negative_keyword_conflict_report_request->Columns, 'columns', 'can get columns');
    is($negative_keyword_conflict_report_request->Scope, 'scope', 'can get scope');
};

1;
